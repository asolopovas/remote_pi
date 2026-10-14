import { sendToManagedChild, managedChildConnected } from "./managed_pipe.js";
import type { ChildProcess } from "node:child_process";
import type { ClientMessage, ManagedAgent, ServerMessage } from "../protocol/types.js";
import { RelayClient } from "../transport/relay_client.js";
import type { Ed25519Keypair } from "../pairing/crypto.js";
import { DecodeError } from "../protocol/codec.js";

export const MANAGED_CONTROL_TYPES = new Set(["user_message", "queued_message_set", "queued_message_clear", "cancel", "ping", "session_sync", "model_set", "thinking_set", "list_models", "extension_ui_response"]);
/** Child IPC is not a general RPC, filesystem, signing, or routing endpoint. */
export function decodeManagedControl(value: unknown): ClientMessage {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new DecodeError("invalid_message", "Invalid managed control");
  const o = value as Record<string, unknown>;
  const text = (v: unknown, max: number) => typeof v === "string" && v.length > 0 && v.length <= max && !v.includes("\0");
  if (!text(o.id, 128) || typeof o.type !== "string" || !MANAGED_CONTROL_TYPES.has(o.type)) throw new DecodeError("unsupported_type", "Unsupported managed control");
  let keys = ["type", "id"];
  switch (o.type) {
    case "user_message":
      keys.push("text", "images", "streaming_behavior");
      if (!text(o.text, 65536) || o.streaming_behavior !== undefined && o.streaming_behavior !== "steer") throw new DecodeError("invalid_message", "Invalid message");
      if (o.images !== undefined && (!Array.isArray(o.images) || o.images.length > 4 || o.images.some(i => !i || !text(i.data, 4_000_000) || !["image/png", "image/jpeg", "image/webp", "image/gif"].includes(i.mime) || Object.keys(i).some(k => k !== "data" && k !== "mime")))) throw new DecodeError("invalid_message", "Invalid images");
      break;
    case "queued_message_set": keys.push("text"); if (!text(o.text, 65536)) throw new DecodeError("invalid_message", "Invalid queue text"); break;
    case "queued_message_clear": keys.push("target_id"); if (o.target_id !== undefined && !text(o.target_id, 128)) throw new DecodeError("invalid_message", "Invalid queue target"); break;
    case "cancel": keys.push("target_id"); if (!text(o.target_id, 128)) throw new DecodeError("invalid_message", "Invalid cancel target"); break;
    case "session_sync": keys.push("limit"); if (o.limit !== undefined && (!Number.isInteger(o.limit) || Number(o.limit) < 1 || Number(o.limit) > 1000)) throw new DecodeError("invalid_message", "Invalid history limit"); break;
    case "model_set": keys.push("provider", "model_id"); if (!text(o.provider, 128) || !text(o.model_id, 256)) throw new DecodeError("invalid_message", "Invalid model"); break;
    case "thinking_set": keys.push("level"); if (!["off", "minimal", "low", "medium", "high", "xhigh", "max"].includes(String(o.level))) throw new DecodeError("invalid_message", "Invalid thinking level"); break;
    case "extension_ui_response":
      keys.push("value", "cancelled", "ask");
      if (o.value !== undefined && typeof o.value !== "string" && typeof o.value !== "boolean" || typeof o.value === "string" && o.value.length > 65536 || o.cancelled !== undefined && typeof o.cancelled !== "boolean") throw new DecodeError("invalid_message", "Invalid UI response");
      if (o.ask !== undefined) throw new DecodeError("unsupported_type", "Structured ask responses are not yet supported in isolated children");
      break;
  }
  if (Object.keys(o).some(k => !keys.includes(k))) throw new DecodeError("invalid_message", "Unexpected control field");
  return o as ClientMessage;
}
const OUTBOUND = new Set(["user_input", "queued_message_state", "steer_consumed", "agent_chunk", "agent_done", "agent_message", "tool_request", "tool_result", "error", "cancelled", "pong", "session_history", "extension_ui_request", "action_ok", "action_error", "models_list"]);
interface Options {
  agent: ManagedAgent; owner: string; child: ChildProcess; url: string; keypair: Ed25519Keypair;
  currentEpoch(): string;
  authorized(epoch: string): Promise<boolean>;
  paired(): Promise<boolean>;
}
/** Parent owns the WS signing identity and routes only one assigned room/Owner.
 * No private key, pair record, arbitrary destination or mesh operation reaches IPC. */
export class ManagedRoom {
  private relay: RelayClient;
  private closed = false;
  private sequence = 0;
  private used = new Set<string>();
  private inflight = 0;
  private outboundInflight = 0;
  constructor(private readonly opts: Options) { this.relay = new RelayClient(opts.url, opts.keypair); }
  async connect(): Promise<void> {
    this.relay.on("message", this.receive);
    this.relay.once("close", this.fail);
    this.opts.child.on("message", this.publish);
    this.opts.child.once("exit", this.close);
    try {
      await this.relay.connect({ managed: true, roomId: this.opts.agent.room_id, roomMeta: { name: this.opts.agent.name, cwd: this.opts.agent.cwd } });
      if (this.closed || !managedChildConnected(this.opts.child)) throw new Error("Child closed during publication");
      sendToManagedChild(this.opts.child, { type: "managed_init", owner: this.opts.owner, room_id: this.opts.agent.room_id, epoch: this.opts.currentEpoch() });
    } catch (error) { this.close(); throw error; }
  }
  revoke(): void { if (!this.closed && managedChildConnected(this.opts.child)) sendToManagedChild(this.opts.child, { type: "managed_revoke", epoch: this.opts.currentEpoch() }); }
  private receive = (line: string): void => {
    if (this.closed || Buffer.byteLength(line) > 6_000_000 || this.inflight >= 8) return;
    let outer: { peer?: unknown; ct?: unknown };
    let message: ClientMessage;
    try {
      outer = JSON.parse(line) as typeof outer;
      if (outer.peer !== this.opts.owner || typeof outer.ct !== "string") return;
      message = decodeManagedControl(JSON.parse(Buffer.from(outer.ct, "base64").toString("utf8")));
    } catch { return; }
    const epoch = this.opts.currentEpoch();
    this.inflight++;
    void (async () => {
      try {
        if (!await this.opts.authorized(epoch) || this.closed || epoch !== this.opts.currentEpoch() || !managedChildConnected(this.opts.child)) {
          if (!this.closed && await this.opts.paired()) this.send(JSON.stringify({ peer: this.opts.owner, ct: Buffer.from(JSON.stringify({ type: "error", in_reply_to: message.id, code: "invalid_message", message: "Launcher locked, expired or unavailable; unlock the launching host" })).toString("base64") }));
          return;
        }
        // Read-only snapshots/pings remain fresh; mutations never evict IDs.
        if (!["ping", "session_sync", "list_models"].includes(message.type)) {
          if (this.used.has(message.id) || this.used.size >= 256) return;
          this.used.add(message.id);
        }
        sendToManagedChild(this.opts.child, { type: "managed_control", epoch, sequence: ++this.sequence, message });
      } finally { this.inflight--; }
    })().catch(() => {});
  };
  private publish = (raw: unknown): void => {
    if (this.closed || this.outboundInflight >= 8 || !raw || typeof raw !== "object") return;
    const envelope = raw as { type?: unknown; epoch?: unknown; message?: unknown };
    if (envelope.type !== "managed_event" || typeof envelope.epoch !== "string") return;
    const message = envelope.message as ServerMessage | undefined;
    if (!message || !OUTBOUND.has(message.type)) return;
    const epoch = envelope.epoch;
    const serialized = JSON.stringify(message);
    if (Buffer.byteLength(serialized) > 6_000_000) return;
    this.outboundInflight++;
    void (async () => {
      try {
        if (!await this.opts.authorized(epoch) || this.closed || epoch !== this.opts.currentEpoch()) return;
        // Child cannot select Owner, room or arbitrary relay control frame.
        this.send(JSON.stringify({ peer: this.opts.owner, ct: Buffer.from(serialized).toString("base64") }));
      } finally { this.outboundInflight--; }
    })().catch(() => {});
  };
  private send(line: string): void { if (!this.closed) this.relay.sendManaged(line, this.fail); }
  private fail = (): void => { if (this.closed) return; this.close(); this.opts.child.kill("SIGKILL"); };
  close = (): void => { this.closed = true; this.opts.child.off("exit", this.close); this.relay.off("message", this.receive); this.relay.off("close", this.fail); this.opts.child.off("message", this.publish); this.relay.terminateManaged(); }
}
