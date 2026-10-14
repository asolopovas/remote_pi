# PIN-protected project launcher (machine/App contract)

This surface controls only this host session's newly launched agents. It does not take over existing Pi sessions, change Relay membership, stop unrelated agents, or shut down the operating system. Linux with working `/bin/bwrap` is required; there is no unrestricted fallback.

## Local operator setup (never run remotely)

Build the extension using its already installed dependencies, then run:

```sh
node /absolute/path/to/pi-extension/dist/bin/launcher.js pin-setup
node /absolute/path/to/pi-extension/dist/bin/launcher.js project-add 'My project' /absolute/project --allow /absolute/project --allow /absolute/extra-folder
node /absolute/path/to/pi-extension/dist/bin/launcher.js project-list
node /absolute/path/to/pi-extension/dist/bin/launcher.js project-remove <project-id>
```

`pin-setup` requires an interactive local terminal, hides input and confirms it. Supply your own 6–12 digit PIN: **no default exists**. Neither CLI arguments nor environment variables accept a PIN. PINs are never logged or stored as plaintext; the verifier uses random 32-byte salt and scrypt (N=32768, r=8, p=1). Synthetic PINs in tests are not operator configuration.

Local data is `~/.pi/remote/launcher/{pin,projects}.json`, files 0600 in a 0700 directory, atomic rename + fsync. Cross-process transactions serialize local edits, PIN resets and persisted attempt/cooldown updates. A crashed transaction leaves `transaction.lock`: operations fail closed; an operator must establish no setup/unlock transaction is alive before removing that stale lock locally. Do not blindly delete locks.

Register exact absolute canonical directories, not glob patterns or a home/system root. Cwd must be within one explicitly allowed folder. Symlink components, `.`/`..`, replacements of any recorded ancestor/directory, host Pi credential directories and runtime overlap are rejected. Removing/re-adding a project creates a new ID. Registry listing is not a filesystem index: it never enumerates unregistered directories, and the phone cannot write registry/PIN/configuration.

Before launch, writable roots are descriptor-pinned and scanned without following symlinks, with a shared 100,000-entry / 5-second / 128-level budget. Hardlinked regular files, nested mounts/filesystems, sockets/FIFOs/devices, inaccessible or oversized trees fail closed. An existing pnpm/hardlinked dependency tree can consequently be unavailable: prepare a private normal-file working copy or smaller project **locally**, then register it; the launcher never deletes, dereferences, changes caches, or silently excludes user files. Launch errors report the preflight category, not file contents. Local `project-list` reports only registered metadata; launch performs the full preflight.

A usable **stored** Pi model credential in `PI_CODING_AGENT_DIR/auth.json` (default `~/.pi/agent/auth.json`) must exist and be private 0600. Use local Pi `/login` if needed; no credentials are invented. Only the configured global `defaultProvider` credential is copied, or the lexicographically first stored provider if no default is configured. Only sanitized `defaultProvider`/`defaultModel` settings accompany it. Literal API keys and OAuth records are supported; host credential commands, environment-only/ambient credentials, arbitrary `models.json`, skills/packages/custom providers and project extensions/settings are not inherited. OAuth refreshes affect only the private child copy. Model selection on the child can select models whose copied provider credential is usable.

For a **future new host process**, not a reload of existing agents, use the operator's explicit trusted endpoint. Example from the intended host working directory, with built extension and an already installed compatible Pi:

```sh
REMOTE_PI_RELAY=https://173.208.50.216 \
REMOTE_PI_DIRECT_CONFIG='{"agent_name":"phone-launch-host","auto_start_relay":true}' \
pi -e /absolute/path/to/pi-extension/dist/index.js
```

This sets a process-local endpoint override, not global configuration. HTTP(S) is the extension configuration form; HTTPS derives WSS internally. Do not disable TLS validation. The phone must use the same Relay endpoint and select this host room. If restored Relay membership does not include its current machine/Owner relationship, reconcile membership explicitly on the phone/operator side; this component does not migrate/change existing pairings. Children reuse parent-owned authenticated machine identity/Owner membership and do **not** need separate QR pairing. No production launch/configuration/activation was performed by implementation tests.

## Frozen additive phone wire contract

Inner JSON travels through the existing authenticated Relay/paired Owner channel. The machine derives Owner from that channel, never payload aliases. Unknown/extra fields, invalid IDs, remote paths/env/commands/flags are rejected. IDs and authority strings are nonempty, control-free strings <=128 characters; optional `name` <=80 characters. PIN is a string matching `^[0-9]{6,12}$`. Use unique IDs for mutations, especially unlock.

```ts
interface LauncherStatus {
  launcher_id: string;
  epoch: string;
  configured: boolean;
  unlocked: boolean;
  expires_at: number | null; // epoch milliseconds, this Owner only
  cooldown_until: number;  // epoch milliseconds, shared local verifier cooldown
}
type LauncherRequest =
  | { type: "project_list" | "launcher_status"; id: string }
  | { type: "launcher_unlock"; id: string; launcher_id: string; epoch: string; pin: string }
  | { type: "launcher_lock" | "launcher_shutdown"; id: string; launcher_id: string; epoch: string }
  | { type: "project_launch"; id: string; launcher_id: string; epoch: string; project_id: string; name?: string }
  | { type: "launcher_agent_stop"; id: string; launcher_id: string; epoch: string; agent_id: string };
type LauncherResult =
  | { type: "project_list_result"; in_reply_to: string; projects: {
      project_id: string; name: string; cwd: string; allowed_folders: string[]
    }[] }
  | { type: "launcher_status_result"; in_reply_to: string; status: LauncherStatus }
  | { type: "launcher_shutdown_result"; in_reply_to: string; stopped: boolean; status: LauncherStatus };
```

Mappings and prerequisites:

| Request | Response | Prerequisite |
|---|---|---|
| `launcher_status` | `launcher_status_result` | Currently paired host Owner |
| `launcher_unlock` | `launcher_status_result` | Current launcher+epoch, local verifier, correct PIN, no cooldown |
| `launcher_lock` | `launcher_status_result` | Currently paired host Owner, current launcher+epoch (can revoke even while locked) |
| `project_list` | `project_list_result` | Current paired Owner **and unexpired unlock** |
| `project_launch` | existing `agent_launch_result` | Current launcher+epoch, paired unlocked Owner, exact registered project ID and successful sandbox/preflight |
| `launcher_agent_stop` | existing `agent_stop_result` | Current launcher+epoch, paired unlocked Owner, this launcher's requesting Owner's agent ID |
| `launcher_shutdown` | `launcher_shutdown_result` | Current launcher+epoch and paired unlocked Owner; revoke before cleanup |
| existing `agent_list` | existing `agent_list_result` | Paired unlocked Owner; snapshot contains only that Owner's records |

Existing launch/stop result `agent` fields remain: `agent_id`, `name`, `cwd`, `room_id`, `state` (`starting/running/stopped/failed`), optional `error`. Agent-list fields remain `available`, optional `launcher_id/reason`, `cwd`, `max_agents` (4), `agents`.

Failures use existing correlated `error` (`in_reply_to`, `code`, `message`), normally `invalid_message`; managed lifecycle can also return `rate_limited`, `timeout`, `internal_error`. Refresh status after unlock failure to obtain cooldown/epoch. The server never echoes the PIN. Legacy arbitrary-cwd `agent_launch` and legacy `agent_stop` are refused; they cannot bypass the protected contract.

### App sequencing/security UX

1. Select the paired host; request `launcher_status` and wait for its reply (initial channel attachment is asynchronous).
2. If `configured:false`, explain local `pin-setup` is required. Do not propose a default or remote setup.
3. Submit a fresh unlock ID with current `launcher_id`/`epoch`; clear the PIN immediately and never retain/replay it.
4. Adopt the returned status/epoch, then fetch `project_list` and `agent_list`. Start only a returned `project_id`; `cwd`/folders are descriptive, not launch inputs.
5. Refresh status after Lock, shutdown, reconnect/expiry or stale authority errors. Do not retain/replay security mutations or substitute a new epoch into an old mutation ID.

Grants last five minutes, are Owner+launcher scoped, and are never restored after host restart/session reload. Verifier replacement invalidates old grants. Wrong attempts impose persisted exponential cooldown from two seconds up to five minutes; only one slow verification is admitted at a time and no attempt-history key is evicted to enable replay. Mutation/credential-check histories are bounded (256); refresh/restart rather than guessing acceptance after capacity errors.

Every successful unlock rotates the global epoch, invalidating pending old-epoch admissions; already-unlocked other Owners keep their remaining expiration but must obtain the new epoch via status. **Lock is global for this launcher**, invalidates all grants/replay authority before any await and leaves already-running children alive. Parent-mediated child-room controls/history/output are also gated; a paired locked caller receives a correlated denial, not child data. Work accepted before Lock can continue in the background; Lock is not a rollback of completed actions.

Shut down means **“Stop your managed agents and lock access.”** It stops only requesting Owner's children in this launcher and globally locks access; other Owners' children and unrelated agents remain running. `stopped:true` means all requesting Owner cleanup completed, including starts in flight. `stopped:false` means incomplete cleanup and access remains locked; inspect locally or unlock and submit a fresh shutdown request to retry safely. Neither operation invokes OS shutdown. Normal host teardown terminates all children it owns.

## Sandbox and parent/child transport scope

The complete child Pi process and its commands run under bubblewrap private mount/user/PID/IPC/UTS namespaces, dropped capabilities, disabled nested user namespaces and parent-death cleanup. Only explicit allowed host folders are writable; exact cwd and folder inodes are pinned, protecting replacement during launch. System binaries/libraries (`/usr`, `/bin`, `/lib*`), DNS/TLS files, the current Node executable, installed Pi package, extension package and cached dependency tree are explicit **read-only runtime allowances**. No host root/home bind, host `~/.pi/remote`, broker UDS, pairing records, signing secret, worker/session identity or arbitrary resource config is exposed. Private HOME/tmp/sessions live on namespace tmpfs. Credential copies pass through immediately unlinked 0600 descriptors and disappear with namespace teardown.

This is OS-enforced **filesystem isolation**, not merely cwd allowlisting and not perfect isolation: allowed mounts change real host files; the selected provider's model credentials are readable by project code; network (including reachable host/local services) remains available and credentials/data can be exfiltrated. It does not defend against a compromised host/kernel or concurrent malicious same-UID local changes after preflight (including newly introduced hardlinks). No automatic mutation/deletion of user files occurs.

Bubblewrap 0.9.0 closes inherited Node IPC fd3 (`--preserve-fds` is unavailable and `--sync-fd` does not pass it to the child). A private preload demultiplexes **namespaced, typed managed frames** over the already inherited stdin/stdout pipes and preserves ordinary Pi RPC JSONL. It has UTF8-safe LF framing, 6MB total/partial frame limits, strict internal fields/directions, monotonic sequences and fail-closed EOF/error/backpressure cleanup. This is not a shell/eval/env/signing/routing endpoint. The parent treats all child output as untrusted and allows only assigned-room protocol events to the launching paired Owner. The parent alone owns per-child Relay challenge signing and paired-owner checks. Readiness requires both actual Pi `get_state` success and successful parent authenticated room publication; timeout/failed publication cleans the child up. No child mesh endpoint exists.

Managed child rooms support bounded existing text/image messages, queue set/clear, cancel, ping, session history, model/thinking selection, model listing and simple extension UI replies. Structured `ask` replies, session-new/compact and arbitrary session/file operations are not enabled by this narrow bridge. The proxy does not automatically restart children or recreate a dropped child-room Relay connection; use the still-owned host list/stop surface after connectivity recovery. Ordinary unrelated Pi rooms keep their prior transport behavior.

## Validation provenance / limitations

Tests use cached Pi SDK/runtime 0.79.10 (not the unrelated global Pi 1.2.0), TypeScript 6, Vitest 4.1.9 and bubblewrap 0.9.0. Current global Pi docs were read for spawn/extension/RPC/credential behavior; CLI options were cross-checked against the actual cached runtime (its `--no-extensions` also excludes MCP; newer `--no-mcp` is unsupported). No package fetching/installation, live Relay contacts, OS keyring writes, real model turns/provider inference requests, global config changes or live-agent reload occurred. Final tests use synthetic provider keys; an early filesystem-only probe copied the existing credential file read-only into its private namespace before fixture isolation was added, without logging values or making a provider request. Real namespace write denial, real cached Pi startup/credential model listing, parent challenge-signature verification and direct child room Lock/shutdown/Owner tests pass against a loopback test Relay. No production App-to-owned-Relay end-to-end run or manual PIN TTY session has been claimed.

Full-suite legacy session-replacement/reconnect failures reproduce using `ac106709` index+tests in this isolated checkout with the same cached dependencies; focused secure-launch and routing tests are separate passing evidence. See the task acceptance report for exact commands/counts and commit.
