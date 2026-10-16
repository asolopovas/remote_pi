import { expect, test } from "vitest";
import { decodeSessionControlRequest, decodeServer, encodeClient } from "./codec.js";
import type { SessionControlRequest, SessionControlResult } from "./types.js";

test("session control frozen opaque-envelope fixtures and strict fields", () => {
  const requests: SessionControlRequest[] = [
    { type: "session_control_status", id: "status", room_id: "exact-room" },
    { type: "session_stop", id: "stop", room_id: "exact-room", token: "confirmation" },
  ];
  const results: SessionControlResult[] = [
    { type: "session_control_status_result", in_reply_to: "status", room_id: "exact-room", can_stop: true, token: "confirmation" },
    { type: "session_control_status_result", in_reply_to: "status", room_id: "exact-room", can_stop: false, reason: "Unlock the launching host first." },
    { type: "session_stop_result", in_reply_to: "stop", room_id: "exact-room", state: "requested" },
    { type: "session_stop_result", in_reply_to: "stop", room_id: "exact-room", state: "stopped" },
  ];
  for (const request of requests) {
    const envelope = { peer: "authenticated-owner", ct: Buffer.from(encodeClient(request).trim()).toString("base64") };
    expect(decodeSessionControlRequest(JSON.parse(Buffer.from(envelope.ct, "base64").toString()))).toEqual(request);
    for (const field of ["pid", "env", "command", "path", "owner", "agent_id"]) expect(() => decodeSessionControlRequest({ ...request, [field]: "untrusted" })).toThrow();
    for (const field of ["id", "room_id", ...(request.type === "session_stop" ? ["token"] : [])]) {
      for (const value of ["", "x".repeat(129), "bad\n", "bad\u0080", 1]) expect(() => decodeSessionControlRequest({ ...request, [field]: value })).toThrow();
    }
  }
  for (const result of results) {
    expect(decodeServer(JSON.stringify(result))).toEqual(result);
    expect(() => decodeServer(JSON.stringify({ ...result, pid: 123 }))).toThrow();
  }
  expect(() => decodeServer(JSON.stringify({ ...results[1], token: "must-not-leak" }))).toThrow();
  expect(() => decodeServer(JSON.stringify({ ...results[0], token: undefined }))).toThrow();
});
