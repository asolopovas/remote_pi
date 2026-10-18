# Pi extension

Host extension, local agent broker, relay client and optional daemon supervisor. Maintainer and author of contributions: **Andrius Solopovas**.

## Build and install this source

Requirements: Node 20+, pnpm and the [Pi coding agent](https://github.com/earendil-works/pi).

```sh
pnpm install --frozen-lockfile
pnpm typecheck
pnpm test
pnpm build
pi install .
```

The public npm package `remote-pi` is a separate upstream distribution. Building this checkout does not publish it or install a service.

In an interactive Pi session:

```text
/remote-pi
/remote-pi pair
```

The first command runs setup when necessary. Setup chooses an agent name and relay auto-start; agents share one machine-local broker session. Scan the pairing QR with your own client build. Pairing is per machine, not per working directory.

## Relay and local configuration

Use HTTP(S) URLs in user-facing settings; transport code derives WS(S). Use HTTPS except for isolated local development.

```text
/remote-pi set-relay https://your-relay.example
/remote-pi config
/remote-pi relay stop
/remote-pi relay start
```

Relay URL precedence:

1. `REMOTE_PI_RELAY` environment variable.
2. `relay` in `~/.pi/remote/config.json`.
3. Built-in third-party relay, `https://relay-rp1.jacobmoura.work`.

The mobile app has its own relay setting and must use the same endpoint. See the [relay guide](../relay/README.md) to self-host. TLS is **not E2E encryption**; trust the relay operator. See [PROTOCOL.md](../PROTOCOL.md) for authentication and routing limits.

| Local path | Purpose |
|---|---|
| `<cwd>/.pi/remote-pi/config.json` | Agent name and relay auto-start for this directory |
| `~/.pi/remote/config.json` | Relay URL |
| `~/.pi/remote/peers.json` | Paired mobile devices |
| `~/.pi/remote/sessions/` | Broker sockets and audit logs |
| `~/.pi/remote/launcher/` | Private launcher verifier and registered projects |

A valid `REMOTE_PI_DIRECT_CONFIG` replaces, rather than merges with, the directory config; invalid/empty overrides fall back to the file. Legacy `session_name` is discarded. Never commit runtime configuration or identities. System keyrings store the host secret where available; headless Linux without a usable keyring falls back to a private `identity.json` with a warning.

Managed workers marked `PI_SUBAGENT_CHILD=1` still join the local mesh but do not inherit automatic mobile exposure. `/remote-pi relay start` remains an explicit opt-in.

## Interactive commands

| Command | Purpose |
|---|---|
| `/remote-pi` | Setup/status and configured connection |
| `/remote-pi setup` | Re-run setup |
| `/remote-pi status` | Local mesh and relay status |
| `/remote-pi stop` | Disconnect this terminal, not all daemons |
| `/remote-pi pair` | Pairing QR and URI |
| `/remote-pi devices` | Paired devices |
| `/remote-pi revoke <shortid>` | Revoke a device listed above |
| `/remote-pi set-relay <url>` | Save an HTTP(S) relay URL |
| `/remote-pi relay [start\|stop\|status]` | Relay-only control; no verb toggles |
| `/remote-pi relay url <url>` | Alias for `set-relay` |
| `/remote-pi config` | Effective relay URL and source |
| `/remote-pi peers` | Discover peers |
| `/remote-pi rename <name>` | Rename this agent |

## Agent messaging and mobile controls

Discover opaque addresses with `list_peers`; copy them verbatim into `agent_send`. Unicast returns a delivery ACK (`received`, `denied` or `timeout`), not another agent's answer. A later reply uses `re` to correlate with the original message ID. Broadcast is fire-and-forget. `agent_request` is deprecated. Read the [agent-network skill](skills/agent-network/SKILL.md) for inbox/reply handling.

Mobile actions include compaction, new session, model/thinking selection and image input where supported. Model/provider capabilities come from the loaded runtime, not a fabricated catalogue. Action failures are scoped to the requesting host/room; an uncertain mutation is not automatically repeated.

Phone starts use registered `project_launch` with PIN authority and Launcher API3, not arbitrary-directory legacy `agent_launch`. Prepare the separate managed runtime before using launches:

```sh
node scripts/prepare-managed-runtime.mjs
```

This copies an already-installed bundled Pi **1.3.0** and its required installed dependencies from the host into a private snapshot, offline. Put that compatible Pi CLI on PATH first; this command does not install missing dependencies. See [phone setup](../SECURE-LAUNCH.md), the [host contract](docs/secure-launcher.md), [session stop controls](docs/session-control.md) and [room display contract](docs/room-display-endpoint.md).

## Optional daemon supervisor

Daemons are distinct from PIN-protected phone-launched children. Install the built local package globally to expose its CLI, then opt into a user-level service:

```sh
npm install -g .
remote-pi install
remote-pi create /absolute/project --name "Project agent"
remote-pi daemons
remote-pi daemon start
remote-pi daemon status
```

Configure/pair the project interactively first. Daemons inherit project tool permissions; running them grants real unattended tool access. Review credentials, permissions and scheduled prompt costs before enabling the service.

| Command | Purpose |
|---|---|
| `remote-pi daemon send <id> "<text>"` | Send a prompt |
| `remote-pi daemon stop` / `restart` | Stop/restart registered daemons |
| `remote-pi remove <id>` | Unregister; local config remains |
| `remote-pi uninstall` | Remove service; registry remains |
| `remote-pi cron add <id> "<expr>" "<prompt>"` | Schedule prompts; minimum interval 60 seconds |
| `remote-pi cron list` / `log` | Inspect schedules and dispatch audit |
| `remote-pi cron run <jobId>` | Dispatch now |
| `remote-pi cron enable\|disable\|remove <jobId>` | Manage a job |

Cron requires a running supervisor; flags include `--tz`, `--wake`, `--no-skip-busy` and `--catchup`. Dispatch logs are not model completion receipts. See [daemon operations and troubleshooting](docs/daemon.md) for service paths, logs and recovery.

## Troubleshooting

- Phone cannot connect: check `/remote-pi config`, matching app URL, TLS and VPN reachability.
- No peer reply: distinguish delivery ACK from a content reply; use `agent_send` with `re` rather than blocking `agent_request`.
- Launcher setup/compatibility error: verify the separate managed runtime, project registration, PIN and sandbox prerequisites; do not weaken security or restart active sessions.
- Upgrade/reload only at an idle-safe boundary. Never stop unrelated agents to make an update convenient.

[MIT license](LICENSE).
