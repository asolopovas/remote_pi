# 94 — Start additional Pi agents from the phone

## Context

The operator requested additional Pi processes from the phone and authorized choosing the best interface. Deliver a phone-first flow; do not add a second LLM launch surface in this slice. Existing persistent daemons are one-per-cwd and resume recent sessions, which is not suitable for fresh additional agents in a folder already in use.

Reuse the existing safe Pi process-launch primitives, without installing services, changing pairing, opening terminals, or replacing an existing agent. One connected, paired host Pi owns bounded, session-scoped headless children. They survive phone disconnects, but are stopped when their launching host Pi exits or its session is replaced, resumed or reloaded. This lifetime must be visible in the phone UI. No automatic crash restart or paid initial prompt. Each launch starts a fresh session with a unique identity, including when sharing a cwd.

## Ownership and structure

Multi-seam implementation, with exclusive isolated owners:

| Lane | Worktree | Files / decision | Gate / handoff |
|---|---|---|---|
| Host | `/home/andrius/src/remote-pi-launch-host` | `pi-extension/` only; authenticated launch protocol, bounded child lifecycle | pnpm checks + tests; committed handoff |
| Phone | `/home/andrius/src/remote-pi-launch-app` | `app/` only; protocol consumer, launch/manage UI, home entry | Flutter analysis/tests; committed handoff |
| Integration | `/home/andrius/src/remote-pi-phone-launch` | coordinator; this plan, canonical protocol docs, integrate reviewed handoffs | exact contract checks + fresh read-only review |

Base: `ff65bf0b`. Shared `/home/andrius/src/remote-pi` belongs to another task: do not write, switch its branch/index, deploy, or modify active services/pairings. Avoid App `session_tile.dart`, chat/voice/theme files belonging to that task. No publication/installation in this slice.

## Wire contract (paired room channel only; incarnation-safe revision)

All requests use existing request IDs and transport. Do not create relay control messages, mesh remote-command endpoints, or accept launches from unpaired peers.

Client messages:

- `{type: "agent_list", id: string}`
- `{type: "agent_launch", id: string, launcher_id: string, cwd: string, name?: string}`
- `{type: "agent_stop", id: string, agent_id: string}`

Managed agent shape:

`{agent_id: string, name: string, cwd: string, room_id: string, state: "starting"|"running"|"stopped"|"failed", error?: string}`

Server messages:

- `{type: "agent_list_result", in_reply_to: string, available: boolean, launcher_id?: string, reason?: string, cwd: string, max_agents: number, agents: ManagedAgent[]}`
- `{type: "agent_launch_result", in_reply_to: string, agent: ManagedAgent}`
- `{type: "agent_stop_result", in_reply_to: string, agent: ManagedAgent}`
- Existing correlated `error` message for validation, unsupported, limits, ownership, launch/stop failures. Use existing supported error codes, not uncoordinated enums.

An available launcher returns a unique `launcher_id` for its host-session incarnation; launch requests must echo it and execution rejects stale IDs. Review identified that `(peer, room)` alone survives host-session replacement while idempotency history does not. The phone retains original pending mutation IDs/payloads across page disposal/reconnect for the app-process lifetime, checks incarnation before replay, and requires fresh confirmation on replacement. An empty snapshot alone never resolves a pending mutation. This additive safety revision does not change relay routing.

`agent_list` is capability discovery; old extensions may silently ignore it, so the phone bounds the timeout and offers an update-extension message, never false availability. `available: false` carries a human-readable reason. `cwd` is the current launcher cwd (default form path). No file browser required: users enter an existing path explicitly. Canonicalize paths and require a directory. Reject control characters, overlong values and malformed input. Do not accept arbitrary binary, env, shell, flags, prompt, or model arguments. Optional name is a human label, not an opaque peer address.

Server-owned agent IDs and unique names prevent collisions; return actual canonical identity. A mutation request ID is an idempotency key scoped to owner/launcher: replay never creates a duplicate, including parallel requests; conflicting mutation payloads fail. Read-only lists always return fresh snapshots and do not consume mutation-history capacity. Saturating bounded mutation history must not disable listing or stopping owned agents: reserve stop capacity, prevent invalid/unowned requests from consuming it, and retain a safe cleanup retry path after transient stop failure. Bound retained records and live children (default max 4). Only the owner that launched an agent may list/stop it, and a stop may never target arbitrary PIDs or pre-existing agents. Stop is idempotent. A paired connection is necessary but still use the authenticated channel's owner identity, not a supplied ID or alias. Recheck revocation as appropriate at dispatch.

`running` means actual child startup/readiness, not merely calling spawn. Launcher startup must settle within a deadline; explicit failures are returned and partial children cleaned up. Room publication may lag: the phone refreshes discovery and shows waiting state rather than claiming a connection that does not exist. Managed children must not recursively expose launching. Fresh sessions must not use `--continue` or resume another agent's JSONL. Strip parent worker/session identity environment that would misclassify children. Ensure shutdown cleanup, stdout/stderr bounds, and signal behavior; reuse `resolvePiSpawn`/`rpcSpawnArgs` or narrowly extend `RpcChild` without regressing persistent daemons.

## Steps and acceptance

1. Host implementation: validate codec, enforce paired-owner boundary, launch/list/stop, deduplication, fresh identity, lifecycle cleanup and failure reporting. Tests cover invalid directory, parallel/replayed requests, spawn/readiness error/timeout, limits, owner isolation, stop safety, and shutdown.
2. Phone implementation: home entry "Start agent" anchored to an existing online paired room; choose host/session through existing app navigation/selection, show host explicitly, load capability/default cwd; form for cwd + optional name; explicit Start confirmation explains trusted local project code and lifetime. Disable duplicate submits and cross-host races. Manage launched agents with refresh, running/failed status and confirmed stop. Existing room discovery/chat remains canonical. Do not silently change targets after reconnect/switch.
3. Integrate: verify exact TS/Dart fixtures, old-server timeout behavior, errors/disconnect/stale replies, host identity, new-room discovery and no regression to existing chat/model actions. Fresh review focuses on process ownership/auth/lifecycle and mobile races.

## Definition of Done

- [x] Phone launch UI and paired-host execution implemented and covered by component/integration tests.
- [x] Same-directory launch does not resume/replace another session (two real Pi processes verified).
- [x] Phone list/stop controls and host owner isolation implemented and tested, including failed-but-live cleanup retries.
- [x] Bounded processes, readiness, idempotency, cleanup and no arbitrary-shell transport are tested.
- [x] UI explains trust/lifetime, reports unsupported/offline/failure, and prevents accidental duplicate starts.
- [x] TS/Dart protocol agreement and focused checks pass; broader checks and unavailable validation reported honestly.
- [x] Independent review completed and accepted findings resolved.
- [x] Isolated patch handed off to other coordinator; shared checkout untouched by this task.

## Verification and coordinated handoff

Code reference: `98fa523ec1c798fd2ce431758a33033c4ea858ad`, branch
`feature/phone-agent-launch`, based on `ff65bf0b`. Integrate the full branch
range, not just component commits: coordinator follow-ups close review findings.
The other coordinator received exact files, reference and validation; its shared
checkout remains reserved for unrelated relay/mobile work. No push, shared merge,
production publish, service changes or device installation were performed.

- Host: `pnpm typecheck`, `pnpm build`, strict compilation of new test files pass;
  full suite **932 passed, 3 platform skips**, 43 files. Final tests isolate
  HOME/REMOTE_PI_HOME. Actual Pi tests verify separate fresh same-cwd sessions,
  authenticated loopback room publication, explicit stop and real IPC-loss exit.
- Phone: `flutter analyze --no-pub` clean; final
  `flutter test --no-pub --concurrency=1` **798 passed**; debug APK builds.
  Earlier runs exposed a roomsStream timing failure reproduced on untouched base;
  it was not patched outside scope. The final complete run passed.
- Independent review accepted fixes for failed-child Stop, uncertain launch
  replay, validation boundaries, lifetime wording and launcher-incarnation safety;
  final targeted verdict **OK**. Active LSP probes found no errors; the last batch
  confirmed three files and left three TS push-only checks inconclusive, covered
  by explicit passing TypeScript checks rather than claimed as LSP-clean.
- APK: `app/build/app/outputs/flutter-apk/app-debug.apk` in the integration
  worktree; SHA-256 `f6c4c6179f4e20b5ce8f89bf8c9f44bc187ee56b8da9e364b42d65d8e518a217`.
  This is a debug artifact, not a signed release or an installed update.

Runtime disclosure: two early worker extension tests lacked a temporary
REMOTE_PI_HOME and could refresh default skill/cache/audit files or briefly join
the local broker. Peers/credentials were mocked; no explicit live pairing or
service mutation was performed. Prior runtime state is unknown; no speculative
restoration was attempted. Later tests were isolated. This caveat was disclosed
to the operator and other coordinator.

### Remaining release verification

- [ ] Coordinate integration with the other task after its writer releases the shared checkout.
- [ ] Install coordinated host/app builds and verify phone launch → discovery → chat → stop on a device.
- [ ] Native macOS/Windows launch smoke, if those platforms are release targets (Linux validated).

## Next

Persistent multi-agent supervisor integration and an LLM launch tool can be added later only if a demonstrated need justifies their separate lifecycle/authorization surface. Phone use does not depend on either.
