import type { AgentRequest, ClientMessage, ServerMessage } from "./types.js";

const SERVER_TYPES = new Set<ServerMessage["type"]>([
  "agent_list_result",
  "agent_launch_result",
  "agent_stop_result",
  "pair_ok",
  "pair_error",
  "user_input",
  "queued_message_state",
  "agent_chunk",
  "agent_done",
  "agent_message",
  "tool_request",
  "tool_result",
  "error",
  "cancelled",
  "pong",
  "bye",
  "session_history",
  // Plan/57 — interactive extension prompt (ask_user via pi-ask).
  "extension_ui_request",
]);

export class DecodeError extends Error {
  constructor(
    public readonly code: "invalid_message" | "unsupported_type",
    message: string,
  ) {
    super(message);
    this.name = "DecodeError";
  }
}

export function encodeClient(msg: ClientMessage): string {
  return JSON.stringify(msg) + "\n";
}

export function decodeServer(line: string): ServerMessage {
  let obj: unknown;
  try {
    obj = JSON.parse(line.trim());
  } catch (e) {
    throw new DecodeError("invalid_message", `not JSON: ${(e as Error).message}`);
  }
  if (
    !obj ||
    typeof obj !== "object" ||
    typeof (obj as Record<string, unknown>).type !== "string"
  ) {
    throw new DecodeError("invalid_message", "missing 'type'");
  }
  const t = (obj as Record<string, unknown>).type as string;
  if (!SERVER_TYPES.has(t as ServerMessage["type"])) {
    throw new DecodeError("unsupported_type", `unknown type: ${t}`);
  }
  return obj as ServerMessage;
}

/** Strict boundary for the launch surface: no shell, flags, environment or aliases. */
export function decodeAgentRequest(value: unknown): AgentRequest {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new DecodeError("invalid_message", "Expected an agent request object");
  }
  const o = value as Record<string, unknown>;
  const text = (v: unknown, max: number): v is string =>
    typeof v === "string" && v.trim().length > 0 && v.length <= max && !/[\x00-\x1f\x7f-\x9f]/.test(v);
  if (!text(o.id, 128)) throw new DecodeError("invalid_message", "Invalid request ID (1–128 characters)");
  let keys: string[];
  switch (o.type) {
    case "agent_list": keys = ["type", "id"]; break;
    case "agent_launch":
      keys = ["type", "id", "cwd", "name"];
      if (!text(o.cwd, 4096) || (o.name !== undefined && !text(o.name, 80))) {
        throw new DecodeError("invalid_message", "Provide an existing directory and an optional name of 1–80 characters");
      }
      break;
    case "agent_stop":
      keys = ["type", "id", "agent_id"];
      if (!text(o.agent_id, 128)) throw new DecodeError("invalid_message", "Invalid managed agent ID");
      break;
    default: throw new DecodeError("unsupported_type", "Unknown agent request");
  }
  if (Object.keys(o).some((key) => !keys.includes(key))) {
    throw new DecodeError("invalid_message", "Unexpected agent request field");
  }
  return o as AgentRequest;
}
