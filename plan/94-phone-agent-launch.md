# 94 — Start additional Pi agents from the phone

## Context

The operator requested additional Pi processes from the phone and authorized choosing the best interface. Deliver a phone-first flow; do not add a second LLM launch surface in this slice. Existing persistent daemons are one-per-cwd and resume recent sessions, which is not suitable for fresh additional agents in a folder already in use.

Reuse the existing safe Pi process-launch primitives, without installing services, changing pairing, opening terminals, or replacing an existing agent. One connected, paired host Pi owns bounded, session-scoped headless children. They survive phone disconnects, but are stopped when their launching host Pi shuts down. This lifetime must be visible in the phone UI. No automatic crash restart or paid initial prompt. Each launch starts a fresh session with a unique identity, including when sharing a cwd.

## Ownership and structure

Multi-seam implementation, with exclusive isolated owners:

| Lane | Worktree | Files / decision | Gate / handoff |
|---|---|---|---|
| Host | `/home/andrius/src/remote-pi-launch-host` | `pi-extension/` only; authenticated launch protocol, bounded child lifecycle | pnpm checks + tests; committed handoff |
| Phone | `/home/andrius/src/remote-pi-launch-app` | `app/` only; protocol consumer, launch/manage UI, home entry | Flutter analysis/tests; committed handoff |
| Integration | `/home/andrius/src/remote-pi-phone-launch` | coordinator; this plan, canonical protocol docs, integrate reviewed handoffs | exact contract checks + fresh read-only review |

Base: `ff65bf0b`. Shared `/home/andrius/src/remote-pi` belongs to another task: do not write, switch its branch/index, deploy, or modify active services/pairings. Avoid App `session_tile.dart`, chat/voice/theme files belonging to that task. No publication/installation in this slice.

## Frozen wire contract (paired room channel only)

All requests use existing request IDs and transport. Do not create relay control messages, mesh remote-command endpoints, or accept launches from unpaired peers.

Client messages:

- `{type: "agent_list", id: string}`
- `{type: "agent_launch", id: string, cwd: string, name?: string}`
- `{type: "agent_stop", id: string, agent_id: string}`

Managed agent shape:

`{agent_id: string, name: string, cwd: string, room_id: string, state: "starting"|"running"|"stopped"|"failed", error?: string}`

Server messages:

- `{type: "agent_list_result", in_reply_to: string, available: boolean, reason?: string, cwd: string, max_agents: number, agents: ManagedAgent[]}`
- `{type: "agent_launch_result", in_reply_to: string, agent: ManagedAgent}`
- `{type: "agent_stop_result", in_reply_to: string, agent: ManagedAgent}`
- Existing correlated `error` message for validation, unsupported, limits, ownership, launch/stop failures. Use existing supported error codes, not uncoordinated enums.

`agent_list` is capability discovery; old extensions may silently ignore it, so the phone bounds the timeout and offers an update-extension message, never false availability. `available: false` carries a human-readable reason. `cwd` is the current launcher cwd (default form path). No file browser required: users enter an existing path explicitly. Canonicalize paths and require a directory. Reject control characters, overlong values and malformed input. Do not accept arbitrary binary, env, shell, flags, prompt, or model arguments. Optional name is a human label, not an opaque peer address.

Server-owned agent IDs and unique names prevent collisions; return actual canonical identity. A request ID is an idempotency key scoped to owner/launcher: replay never creates a duplicate, including parallel requests; conflicting payloads fail. Bound retained records and live children (default max 4). Only the owner that launched an agent may list/stop it, and a stop may never target arbitrary PIDs or pre-existing agents. Stop is idempotent. A paired connection is necessary but still use the authenticated channel's owner identity, not a supplied ID or alias. Recheck revocation as appropriate at dispatch.

`running` means actual child startup/readiness, not merely calling spawn. Launcher startup must settle within a deadline; explicit failures are returned and partial children cleaned up. Room publication may lag: the phone refreshes discovery and shows waiting state rather than claiming a connection that does not exist. Managed children must not recursively expose launching. Fresh sessions must not use `--continue` or resume another agent's JSONL. Strip parent worker/session identity environment that would misclassify children. Ensure shutdown cleanup, stdout/stderr bounds, and signal behavior; reuse `resolvePiSpawn`/`rpcSpawnArgs` or narrowly extend `RpcChild` without regressing persistent daemons.

## Steps and acceptance

1. Host implementation: validate codec, enforce paired-owner boundary, launch/list/stop, deduplication, fresh identity, lifecycle cleanup and failure reporting. Tests cover invalid directory, parallel/replayed requests, spawn/readiness error/timeout, limits, owner isolation, stop safety, and shutdown.
2. Phone implementation: home entry "Start agent" anchored to an existing online paired room; choose host/session through existing app navigation/selection, show host explicitly, load capability/default cwd; form for cwd + optional name; explicit Start confirmation explains trusted local project code and lifetime. Disable duplicate submits and cross-host races. Manage launched agents with refresh, running/failed status and confirmed stop. Existing room discovery/chat remains canonical. Do not silently change targets after reconnect/switch.
3. Integrate: verify exact TS/Dart fixtures, old-server timeout behavior, errors/disconnect/stale replies, host identity, new-room discovery and no regression to existing chat/model actions. Fresh review focuses on process ownership/auth/lifecycle and mobile races.

## Definition of Done

- [ ] Phone can launch a fresh additional Pi in a chosen existing directory on a paired online host.
- [ ] Same-directory launch does not resume/replace another session.
- [ ] Phone can see and stop only agents it is authorized to manage.
- [ ] Bounded processes, readiness, idempotency, cleanup and no arbitrary-shell transport are tested.
- [ ] UI explains trust/lifetime, reports unsupported/offline/failure, and prevents accidental duplicate starts.
- [ ] TS/Dart protocol agreement and focused checks pass; broader checks and unavailable validation reported honestly.
- [ ] Independent review completed and accepted findings resolved.
- [ ] Isolated patch handed off to other coordinator; shared checkout untouched.

## Next

Persistent multi-agent supervisor integration and an LLM launch tool can be added later only if a demonstrated need justifies their separate lifecycle/authorization surface. Phone use does not depend on either.
