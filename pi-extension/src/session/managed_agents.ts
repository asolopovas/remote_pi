import { spawn, type ChildProcess, type SpawnOptions } from "node:child_process";
import { randomUUID } from "node:crypto";
import { realpath, stat } from "node:fs/promises";
import { resolve } from "node:path";
import type { AgentRequest, ManagedAgent, ServerMessage } from "../protocol/types.js";
import { resolvePiSpawn, rpcSpawnArgs } from "../daemon/rpc_child.js";
import { roomIdFor } from "../rooms.js";
import { sanitizeSegment } from "./local_config.js";

export const MANAGED_CHILD_ENV = "REMOTE_PI_MANAGED_CHILD";
export const MAX_MANAGED_AGENTS = 4;
const MAX_RECORDS = 32;
const MAX_REQUESTS = 256;
const RESERVED_STOPS_PER_AGENT = 3;

/** Keep host credentials/config resolution, not its worker or session identity. */
export function managedChildEnv(parent: NodeJS.ProcessEnv, name: string): NodeJS.ProcessEnv {
  const env = { ...parent };
  for (const key of Object.keys(env)) {
    if (/^PI_(SUBAGENTS?|WORKER|SESSION|PARENT|AGENT)(_|$)/.test(key) || key === "PI_ASYNC_NATIVE_RUNNER" ||
        /^(TUIOS_|COCKPIT_|CMUX_)/.test(key) ||
        ["REMOTE_PI_DIRECT_CONFIG", "REMOTE_PI_DAEMON", "PI_CODING_AGENT_SESSION_DIR", MANAGED_CHILD_ENV].includes(key)) delete env[key];
  }
  env.REMOTE_PI_DAEMON = "1";
  env[MANAGED_CHILD_ENV] = "1";
  env.REMOTE_PI_DIRECT_CONFIG = JSON.stringify({ agent_name: name, auto_start_relay: true });
  return env;
}

interface Entry {
  owner: string;
  agent: ManagedAgent;
  child?: ChildProcess;
  exited: Promise<void>;
  stop?: Promise<void>;
  stopRequested?: boolean;
  reservedStops: number;
}
export type ManagedSpawn = (command: string, args: readonly string[], options: SpawnOptions) => ChildProcess;

interface Options {
  cwd: string;
  extensionPath: string;
  piBin?: string;
  readinessMs?: number;
  stopMs?: number;
  spawn?: ManagedSpawn;
  env?: NodeJS.ProcessEnv;
}
class AgentFailure extends Error {
  constructor(readonly code: "invalid_message" | "rate_limited" | "timeout" | "internal_error", message: string) { super(message); }
}

/** Session-owned, never registered with supervisord, never automatically restarted.
 * Retain all accepted idempotency keys; once bounded history fills, reject new
 * mutations rather than evicting a key and accidentally launching its replay.
 */
export class ManagedAgents {
  private readonly entries = new Map<string, Entry>();
  private readonly requests = new Map<string, { payload: string; result: Promise<ServerMessage> }>();
  private ordinaryRequests = 0;
  private closing = false;
  private readonly killAtExit = () => {
    for (const entry of this.entries.values()) { try { entry.child?.kill("SIGKILL"); } catch { /* already gone */ } }
  };

  constructor(private readonly opts: Options) { process.once("exit", this.killAtExit); }

  async handle(owner: string, request: AgentRequest, authorized: () => Promise<boolean>): Promise<ServerMessage> {
    const error = (code: "invalid_message" | "rate_limited" | "timeout" | "internal_error", message: string): ServerMessage =>
      ({ type: "error", in_reply_to: request.id, code, message });
    const key = JSON.stringify([owner, request.id]);
    const payload = JSON.stringify(request.type === "agent_launch"
      ? [request.type, request.cwd, request.name ?? null]
      : request.type === "agent_stop" ? [request.type, request.agent_id] : [request.type]);
    try {
      if (this.closing || !await authorized()) return error("invalid_message", "Launcher closed or Owner no longer paired");
    } catch { return error("internal_error", "Could not verify Owner pairing"); }
    if (this.closing) return error("invalid_message", "Launcher closed");
    const previous = this.requests.get(key);
    if (previous) return previous.payload === payload ? previous.result : error("invalid_message", "Request ID already used with a different payload");
    // Read-only snapshots are fresh and never consume mutation history. Any
    // retained mutation ID still takes precedence for replay/conflict checks.
    if (request.type === "agent_list") return {
      type: "agent_list_result", in_reply_to: request.id, available: true,
      cwd: this.opts.cwd, max_agents: MAX_MANAGED_AGENTS,
      agents: [...this.entries.values()].filter(e => e.owner === owner).map(e => ({ ...e.agent })),
    };
    const stopEntry = request.type === "agent_stop" ? this.entries.get(request.agent_id) : undefined;
    if (request.type === "agent_stop" && (!stopEntry || stopEntry.owner !== owner)) {
      return error("invalid_message", "Unknown agent or not owned by this Owner");
    }
    if (stopEntry && !stopEntry.child && stopEntry.agent.state !== "starting") {
      stopEntry.agent.state = "stopped";
      delete stopEntry.agent.error;
      return { type: "agent_stop_result", in_reply_to: request.id, agent: { ...stopEntry.agent } };
    }
    // Preserve cleanup capacity after normal history fills. Invalid/unowned
    // targets above never spend the per-record reserve. Failed attempts stay
    // replayable; a new ID retries cleanup up to this explicit bounded limit.
    if (this.ordinaryRequests >= MAX_REQUESTS) {
      if (!stopEntry) return error("rate_limited", "Launcher mutation history is full; start a new host session");
      if (stopEntry.reservedStops >= RESERVED_STOPS_PER_AGENT) return error("rate_limited", "Cleanup retry history exhausted; shut down the host session and inspect the host if Pi remains alive");
      stopEntry.reservedStops += 1;
    } else this.ordinaryRequests += 1;
    const result = (async (): Promise<ServerMessage> => {
      try {
        if (this.closing) throw new AgentFailure("invalid_message", "Launcher closed");
        if (request.type === "agent_launch") {
          const agent = await this.launch(owner, request, authorized);
          return { type: "agent_launch_result", in_reply_to: request.id, agent: { ...agent } };
        }
        const entry = this.entries.get(request.agent_id);
        if (!entry || entry.owner !== owner) throw new AgentFailure("invalid_message", "Unknown agent or not owned by this Owner");
        await this.stop(entry);
        return { type: "agent_stop_result", in_reply_to: request.id, agent: { ...entry.agent } };
      } catch (err) {
        return error(err instanceof AgentFailure ? err.code : "internal_error",
          err instanceof AgentFailure ? err.message : "Agent operation failed; check the host Pi installation and directory access");
      }
    })();
    this.requests.set(key, { payload, result });
    return result;
  }

  private async launch(owner: string, request: Extract<AgentRequest, { type: "agent_launch" }>, authorized: () => Promise<boolean>): Promise<ManagedAgent> {
    let cwd: string;
    try {
      cwd = await realpath(resolve(this.opts.cwd, request.cwd));
      if (!(await stat(cwd)).isDirectory()) throw new Error("not directory");
    } catch { throw new AgentFailure("invalid_message", "Directory does not exist, is inaccessible, or is not a directory"); }
    const label = request.name ? sanitizeSegment(request.name) : "phone-agent";
    if (!label) throw new AgentFailure("invalid_message", "Name is not a usable agent label");
    if (!await authorized() || this.closing) throw new AgentFailure("invalid_message", "Launcher closed or Owner no longer paired");
    // No awaits between admission and inserting a starting record: parallel
    // launches share the same global live-process and retained-record bounds.
    if ([...this.entries.values()].filter(e => e.child || e.agent.state === "starting").length >= MAX_MANAGED_AGENTS) {
      throw new AgentFailure("rate_limited", "Maximum of 4 managed agents reached; stop one first");
    }
    if (this.entries.size >= MAX_RECORDS) throw new AgentFailure("rate_limited", "Launcher history is full (32 agents); start a new host session");
    const id = randomUUID();
    const name = `${label}-${id}`;
    const agent: ManagedAgent = { agent_id: id, name, cwd, room_id: roomIdFor(cwd, name), state: "starting" };
    const entry: Entry = { owner, agent, exited: Promise.resolve(), reservedStops: 0 };
    this.entries.set(id, entry);
    try {
      await this.start(entry);
      if (this.closing || !await authorized()) throw new AgentFailure("invalid_message", "Launcher closed or Owner revoked during startup");
      if (!entry.child || entry.stopRequested) throw new AgentFailure("internal_error", "Pi stopped or exited during startup");
      agent.state = "running";
      return agent;
    } catch (err) {
      if (!entry.stopRequested) {
        agent.state = "failed";
        agent.error = err instanceof AgentFailure ? err.message : "Could not start Pi; verify that pi is on PATH and the extension is built";
      }
      try { await this.stop(entry, false); } catch { agent.error = (agent.error ?? "Startup stopped") + "; cleanup failed — host shutdown will retry"; }
      throw err instanceof AgentFailure ? err : new AgentFailure("internal_error", agent.error ?? "Startup stopped");
    }
  }

  private start(entry: Entry): Promise<void> {
    return new Promise<void>((resolveReady, reject) => {
      const target = resolvePiSpawn(this.opts.piBin ?? "pi");
      const child = (this.opts.spawn ?? spawn)(target.command,
        [...target.prefixArgs, ...rpcSpawnArgs(this.opts.extensionPath, entry.agent.name, false)],
        { cwd: entry.agent.cwd, env: managedChildEnv(this.opts.env ?? process.env, entry.agent.name),
          stdio: ["pipe", "pipe", "pipe", "ipc"], windowsHide: true });
      entry.child = child;
      let ready = false;
      let rpcReady = false;
      let settled = false;
      let buf = "";
      const timer = setTimeout(() => finish(new AgentFailure("timeout", "Pi startup timed out; check project extensions, relay connectivity and host identity storage")), this.opts.readinessMs ?? 20_000);
      const finish = (error?: Error) => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        if (error) reject(error);
        else resolveReady();
      };
      const checkReady = () => { if (ready && rpcReady) finish(); };
      entry.exited = new Promise<void>((resolveExit) => {
        child.once("exit", (code, signal) => {
          entry.child = undefined;
          if (entry.agent.state !== "stopped" && !entry.stop) {
            entry.agent.state = "failed";
            entry.agent.error = `Pi exited (code ${code ?? "none"}, signal ${signal ?? "none"}); no automatic restart`;
          }
          finish(new AgentFailure("internal_error", entry.agent.error ?? "Pi exited before readiness"));
          resolveExit();
        });
        child.once("error", (err: NodeJS.ErrnoException) => {
          if (!child.pid) { entry.child = undefined; resolveExit(); }
          finish(new AgentFailure("internal_error", err.code === "ENOENT"
            ? "Pi executable not found; install Pi and make it available on the host PATH"
            : "Unable to start Pi; check executable and directory permissions"));
        });
      });
      child.stdin?.on("error", () => finish(new AgentFailure("internal_error", "Pi RPC input closed during startup")));
      // Never forward project logs (which may contain secrets). Drain stderr;
      // retain no logs, and bound the partial JSON line buffer on stdout.
      child.stderr?.on("data", () => {});
      child.stdout?.on("data", (chunk: Buffer) => {
        buf += chunk.toString();
        if (buf.length > 65_536) { buf = ""; finish(new AgentFailure("internal_error", "Pi startup output exceeded the RPC line limit")); return; }
        let end: number;
        while ((end = buf.indexOf("\n")) !== -1) {
          const line = buf.slice(0, end); buf = buf.slice(end + 1);
          try {
            const data = JSON.parse(line) as { type?: string; command?: string; id?: string; success?: boolean };
            if (data.type === "response" && data.command === "get_state" && data.id === entry.agent.agent_id && data.success === true) {
              rpcReady = true; checkReady();
            }
          } catch { /* bounded non-RPC extension output */ }
        }
      });
      child.on("message", (message: unknown) => {
        const m = message as { type?: unknown; name?: unknown; room_id?: unknown; ok?: unknown } | null;
        if (m?.type !== "remote_pi_managed_ready") return;
        if (m.ok !== true || m.name !== entry.agent.name || m.room_id !== entry.agent.room_id) {
          finish(new AgentFailure("internal_error", "Child could not publish its independent room; check relay, identity storage and name admission"));
        } else { ready = true; checkReady(); }
      });
      child.once("spawn", () => {
        child.stdin?.write(JSON.stringify({ type: "get_state", id: entry.agent.agent_id }) + "\n");
      });
    });
  }

  private stop(entry: Entry, markStopped = true): Promise<void> {
    if (markStopped) entry.stopRequested = true;
    if (entry.stop) return entry.stop;
    if (!entry.child) { if (markStopped) { entry.agent.state = "stopped"; delete entry.agent.error; } return Promise.resolve(); }
    const child = entry.child;
    entry.stop = (async () => {
      const delay = this.opts.stopMs ?? 3_000;
      const wait = async () => {
        let timer: ReturnType<typeof setTimeout> | undefined;
        const exited = await Promise.race([entry.exited.then(() => true), new Promise<false>(r => { timer = setTimeout(() => r(false), delay); })]);
        clearTimeout(timer); return exited;
      };
      child.stdin?.end();
      child.kill("SIGTERM");
      if (!await wait()) { child.kill("SIGKILL"); if (!await wait()) throw new AgentFailure("timeout", "Pi did not exit after SIGKILL; host shutdown will retry cleanup"); }
      if (markStopped) { entry.agent.state = "stopped"; delete entry.agent.error; }
    })().finally(() => { entry.stop = undefined; });
    return entry.stop;
  }

  async shutdown(): Promise<void> {
    this.closing = true;
    await Promise.all([...this.entries.values()].map(e => this.stop(e).catch(() => { /* exit hook + IPC disconnect remain last-resort guards */ })));
    if (![...this.entries.values()].some(e => e.child)) process.off("exit", this.killAtExit);
  }
}
