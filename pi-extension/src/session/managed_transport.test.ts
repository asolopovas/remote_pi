import { test, expect, vi, afterEach } from "vitest";
import { EventEmitter } from "node:events";
import type { ChildProcess } from "node:child_process";
import { generateEd25519Keypair } from "../pairing/crypto.js";

const sockets: MockWS[] = [];
class MockWS extends EventEmitter {
  static OPEN = 1;
  readyState = 1;
  bufferedAmount = 0;
  maxBuffered = 0;
  stall = false;
  throwSend = false;
  callbackError = false;
  sent: string[] = [];
  callbacks: (() => void)[] = [];
  constructor(_url: string) { super(); sockets.push(this); queueMicrotask(() => this.emit("open")); }
  send(line: string, callback?: (error?: Error) => void): void {
    if (this.throwSend) throw new Error("write failed");
    this.sent.push(line);
    if (JSON.parse(line).type === "hello") queueMicrotask(() => this.emit("message", Buffer.from(JSON.stringify({ type: "challenge", nonce: Buffer.alloc(32).toString("base64") }))));
    if (this.callbackError) { callback?.(new Error("completion failed")); return; }
    if (this.stall) {
      const bytes = Buffer.byteLength(line) + 14;
      this.bufferedAmount += bytes;
      this.maxBuffered = Math.max(this.maxBuffered, this.bufferedAmount);
      this.callbacks.push(() => { this.bufferedAmount -= bytes; callback?.(); });
    } else callback?.();
  }
  terminate(): void { this.readyState = 3; this.emit("close"); }
  close(): void { this.terminate(); }
}
vi.mock("ws", () => ({ default: MockWS }));
const { ManagedRoom } = await import("./managed_transport.js");
const { MANAGED_SEND_LIMIT, RelayClient } = await import("../transport/relay_client.js");
const rooms: InstanceType<typeof ManagedRoom>[] = [];
afterEach(() => { for (const room of rooms) room.close(); rooms.length = 0; sockets.length = 0; });
async function fixture() {
  const child = Object.assign(new EventEmitter(), { connected: true, send: vi.fn(), kill: vi.fn(), exitCode: null, signalCode: null }) as unknown as ChildProcess;
  let epoch = "e", unlocked = true, paired = true;
  const authorized = vi.fn(async (e: string) => paired && unlocked && e === epoch);
  const pairedCheck = vi.fn(async () => paired);
  const room = new ManagedRoom({ agent: { agent_id: "a", name: "assigned", cwd: "/assigned", room_id: "assigned-room", state: "running" }, child, owner: "owner", url: "ws://fixture", keypair: generateEd25519Keypair(),
    currentEpoch: () => epoch, authorized,
    paired: pairedCheck });
  rooms.push(room); await room.connect(); const ws = sockets.at(-1)!;
  const emit = (message: object) => child.emit("message", { type: "managed_event", epoch, message });
  return { child, room, ws, emit, authorized, pairedCheck, lock() { epoch = "locked"; unlocked = false; room.revoke(); }, unlock() { epoch = "unlocked"; unlocked = true; room.revoke(); }, unpair() { paired = false; } };
}
const settle = () => new Promise<void>(resolve => setImmediate(resolve));

test("managed valid near-limit output on a non-reading WS is byte bounded and overflow terminates only its child", async () => {
  const f = await fixture(); f.ws.stall = true;
  const message: import("../protocol/types.js").ServerMessage = { type: "agent_chunk", in_reply_to: "accepted", delta: "x".repeat(5_900_000) };
  for (let i = 0; i < 12; i++) { f.emit(message); await settle(); }
  expect(f.ws.maxBuffered).toBeLessThanOrEqual(12_000_000);
  expect(MANAGED_SEND_LIMIT).toBe(12_000_000);
  expect(f.ws.readyState).toBe(3);
  expect(f.child.kill).toHaveBeenCalledExactlyOnceWith("SIGKILL");
  const queued = f.ws.sent.length; f.emit(message); await settle(); expect(f.ws.sent).toHaveLength(queued);
  for (const complete of f.ws.callbacks) complete();
  expect(f.child.kill).toHaveBeenCalledTimes(1);
});

test.each(["callback", "throw", "close"])("managed %s send failures clean up room and child without retry", async failure => {
  const f = await fixture();
  if (failure === "callback") f.ws.callbackError = true;
  if (failure === "throw") f.ws.throwSend = true;
  if (failure === "close") f.ws.terminate();
  f.emit({ type: "pong", in_reply_to: "p" }); await settle();
  expect(f.child.kill).toHaveBeenCalledExactlyOnceWith("SIGKILL"); expect(f.ws.readyState).toBe(3);
  f.room.close(); f.emit({ type: "pong", in_reply_to: "p2" }); await settle();
  expect(f.child.kill).toHaveBeenCalledTimes(1);
});

test("managed error frames share the event byte cap; ordinary send semantics stay unchanged", async () => {
  const f = await fixture(); f.ws.bufferedAmount = MANAGED_SEND_LIMIT - 10;
  f.lock();
  f.ws.emit("message", Buffer.from(JSON.stringify({ peer: "owner", ct: Buffer.from(JSON.stringify({ type: "ping", id: "locked" })).toString("base64") })));
  await settle(); expect(f.child.kill).toHaveBeenCalledExactlyOnceWith("SIGKILL");
  const relay = new RelayClient("ws://ordinary", generateEd25519Keypair()); await relay.connect();
  const ordinary = sockets.at(-1)!; ordinary.bufferedAmount = MANAGED_SEND_LIMIT;
  expect(() => relay.send('{"ordinary":true}')).not.toThrow(); relay.close();
});

test("completion accounting bounds even under-reported bufferedAmount and frees completed writes", async () => {
  const relay = new RelayClient("ws://fixture", generateEd25519Keypair()); await relay.connect();
  const ws = sockets.at(-1)!; ws.stall = true; const fail = vi.fn();
  relay.sendManaged(JSON.stringify({ data: "x".repeat(6_000_000) }), fail);
  ws.bufferedAmount = 0;
  relay.sendManaged(JSON.stringify({ data: "x".repeat(6_000_000) }), fail);
  expect(fail).toHaveBeenCalledTimes(1);
  ws.callbacks[0]!(); ws.bufferedAmount = 0;
  relay.sendManaged(JSON.stringify({ data: "x".repeat(6_000_000) }), fail);
  expect(fail).toHaveBeenCalledTimes(1); relay.terminateManaged();
});

test("closing during pending managed completion neither retries nor kills an already disposed child", async () => {
  const f = await fixture(); f.ws.stall = true;
  f.emit({ type: "pong", in_reply_to: "pending" }); await settle();
  expect(f.ws.callbacks).toHaveLength(1);
  f.room.close(); f.ws.callbacks[0]!(); f.ws.callbacks[0]!();
  expect(f.child.kill).not.toHaveBeenCalled();
  expect(f.ws.readyState).toBe(3);
});
