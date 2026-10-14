import { describe, expect, test } from "vitest";
import { decodeAgentRequest, decodeServer, encodeClient } from "./codec.js";

describe("agent request codec (plan 94 frozen contract)", () => {
  test.each([
    { type: "agent_list", id: "list" },
    { type: "agent_launch", id: "launch", cwd: "/project" },
    { type: "agent_launch", id: "launch", cwd: "/project", name: "Reviewer" },
    { type: "agent_stop", id: "stop", agent_id: "server-owned-id" },
  ] as const)("valid $type", request => {
    expect(decodeAgentRequest(JSON.parse(encodeClient(request)))).toEqual(request);
  });
  test.each([
    null, [], "agent_list", {}, { type: "unknown", id: "x" },
    { type: "agent_list" }, { type: "agent_list", id: 3 }, { type: "agent_list", id: "" },
    { type: "agent_list", id: "\n" }, { type: "agent_list", id: "x".repeat(129) },
    { type: "agent_launch", id: "x", cwd: " " }, { type: "agent_launch", id: "x", cwd: [] },
    { type: "agent_launch", id: "x", cwd: "/a\u0000" }, { type: "agent_launch", id: "x", cwd: "x".repeat(4097) },
    { type: "agent_launch", id: "x", cwd: "/a", name: null }, { type: "agent_launch", id: "x", cwd: "/a", name: "" },
    { type: "agent_launch", id: "x", cwd: "/a", name: "x".repeat(81) }, { type: "agent_launch", id: "x", cwd: "/a", name: "a\u0085" },
    { type: "agent_launch", id: "x", cwd: "/a", flags: ["--continue"] },
    { type: "agent_launch", id: "x", cwd: "/a", env: {} },
    { type: "agent_launch", id: "x", cwd: "/a", prompt: "paid initial prompt" },
    { type: "agent_launch", id: "x", cwd: "/a", owner: "alias" },
    { type: "agent_launch", id: "x", cwd: "/a", binary: "/bin/sh" },
    { type: "agent_stop", id: "x", agent_id: 123 }, { type: "agent_stop", id: "x", agent_id: "\r" },
    { type: "agent_stop", id: "x", agent_id: "a", pid: 123 },
  ])("rejects malformed/extraneous shape %#", request => expect(() => decodeAgentRequest(request)).toThrow());
  test("accepts frozen result envelopes", () => {
    const agent = { agent_id: "id", name: "reviewer-id", cwd: "/project", room_id: "room", state: "running" };
    for (const result of [
      { type: "agent_list_result", in_reply_to: "list", available: true, cwd: "/project", max_agents: 4, agents: [agent] },
      { type: "agent_launch_result", in_reply_to: "launch", agent },
      { type: "agent_stop_result", in_reply_to: "stop", agent: { ...agent, state: "stopped" } },
    ]) expect(decodeServer(JSON.stringify(result))).toEqual(result);
  });
});
