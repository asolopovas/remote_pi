# Secure phone project launcher

Current source is reconciled in `/home/andrius/src/remote-pi`. The six historical
implementation worktrees were removed after source-equivalence/activity checks;
all branch histories remain, and local-only config is privately backed up.
See plans100–104 for checkout reconciliation, access recovery, machine selection,
exact model defaults and actionable session removal.

## From the phone

1. Tap **+**. With one paired machine, Start opens directly; multiple machines
   appear once each in the host chooser. The form shows **Host**, the actual chosen
   launching **Session**, and compatible **Launcher API3**. Sessions are not extra machines;
   endpoint resolution is read-only before PIN/Start, and recovery stays tied to
   an existing agent's actual parent.
2. First use: enter and confirm a6–12 digit PIN, then **Create PIN & unlock**.
   Successful creation authorizes only this paired Owner; no third entry is needed.
   If a PIN already exists, enter it once and tap **Unlock**.
3. Select a registered project and confirm Start. The app waits for actual running
   readiness and discovery, then opens that exact new agent's chat.
4. Use the agent's confirmed Stop control when finished. No prompt/model turn is
   sent merely by Start.

Keep the PIN private; never send it in chat. Fields are cleared on submission and
lifecycle/authority changes, and are not remembered or automatically replayed.
Older hosts can return configured-but-locked after setup; those need ordinary
unlock without reusing a retained PIN. New starts require API3 so an older host
cannot silently substitute GPT5.5 for an unresolved configured model. API2 still
supports existing-agent controls and actual-parent recovery. A compatibility error
means the loaded host needs a safe update, not that the PIN must be recreated.
An existing PIN is never overwritten remotely.

Personal Samsung build55 is installed in place with pairing/app identity preserved.
Earlier build54 ADB acceptance verified one-machine/two-session Start directly,
displaying **Host: main-linux** once plus its selected Session detail. Build55's
new-model Start acceptance awaits a safely loaded API3 host; do not confuse the
published package or synthetic model fixture with that live acceptance.
A managed dotfiles agent was successfully launched on the phone. Its original host
and child later disappeared during build time; this task did not Stop/restart them.
Exact recovery on that old child could therefore not be physically exercised.

Session info now distinguishes authoritative access metadata from unknown/legacy
state. **Check access / Unlock launching host** resolves the actual parent when
metadata is available; older hosts require explicit same-peer session selection,
not a guessed parent. Unlock recovery returns to the exact child and obtains fresh
controls, never replaying a Stop token. Grants remain per-Owner/per-launching-session
and expire after five minutes; this is not a machine-wide unlock. The requested
lifetime-policy change is awaiting the operator's decision.

## Session removal

Long-press a running session → **Agent controls…** opens that exact session's info;
Stop remains a separate explicitly confirmed action. Build55 physical acceptance
verified the enabled menu and info route, then closed info without Stop.

Offline **Remove from list…** removes local session metadata only, not host history,
pairing or a process. It requires confirmation and fresh authoritative offline
state; changes during confirmation/storage fail visibly instead of deleting a
resurrected session. Offline persistence/removal is regression-tested, not claimed
as a destructive test against a real user's phone history.

## Host requirements and recovery

- A compatible running paired API3 host for new starts; children stop when that launching host closes,
  changes session or reloads. Phone disconnect alone does not stop them.
- Registered project/folder permissions and a working Linux bubblewrap sandbox.
- Stored private model credentials: regular nonsymlink user-owned0600 `auth.json`.
- The fixed host `settings.json` **may be a dotfiles symlink**. The launcher reads
  its canonical regular user-owned bounded file and copies only validated model
  defaults, not arbitrary resources/configuration. Normal0664 settings are supported.
- New children use a validated complete private Pi1.3.0 runtime snapshot, explicit
  configured provider/model and verified actual provider/id/API/capabilities before
  room publication. Cached Pi0.79.10 lacks builtin Sol and silently selected5.5;
  merely renaming its descriptor is not a compatible adapter upgrade. Unsupported
  or missing explicit defaults now fail without substitution. Only validated model
  defaults/selected-provider credentials cross the existing sandbox boundary.
- Unsupported/unsafe project trees still fail closed. The large `remote-pi` checkout
  previously exceeded elapsed preflight limits; four other registered trees passed
  the metadata scan. A previous scan is not a guarantee after project mutation.

Use **Check status** after an uncertain result; it does not repeat Start. Never
assume a timeout means no agent was created. Known preparation failures provide
safe prerequisite-specific guidance, not the misleading generic PATH/build advice.
Do not weaken filesystem or credential protection to bypass an error.

Project registration and existing-PIN recovery remain local-only alternatives:

```sh
remote-pi-launcher project-add 'My project' /absolute/project --allow /absolute/project
remote-pi-launcher project-list
# Optional local PIN setup/recovery: hidden interactive input, not shell arguments.
remote-pi-launcher pin-setup
```

Use only directories you explicitly authorize. Do not run placeholder paths.
Existing Pi processes require an idle-safe reload to load a new immutable runtime;
never restart or reload an active job just to update the launcher. New Pi processes
load the installed package's selected runtime automatically. Do not delete an
immutable release while any session can still use it.

## Delivery and evidence

- Owned Relay: `https://173.208.50.216` / `wss://173.208.50.216`.
- APK: `app/build/releases/code55/accepted/code55.apk` (ARM64 Flutter payload, version1.2.0/code55).
- SHA256: `84630429f33566576e9e84767a96cb01b4531aa8088ace1e023f035149860562`.
- Same signer, UID10054 and original install time preserved; installed APK pullback
  is byte-identical. Fresh compiled AOT matches packaged `libapp.so`.
- Plan101 review recheck OK after a binding-race correction; App full serial951 tests
  pass. Independent packaging gates:121 focused+49 selected host tests plus one
  integration test,153 focused App tests and scoped analyzer clean. Prior full host
  suite1068 passes/3 skips is retained, not called a fresh packaging run.
- Full immutable-layout real bubblewrap/Pi synthetic fixtures verify symlinked
  settings red→green, create-only grant, running, signed loopback challenge, exact
  parent/access metadata and own-fixture Stop; no model turns. Not a substitute for
  actual-phone recovery acceptance. No running host was reloaded for code53; new
  metadata is enabled on future safe loads, with App legacy fallback meanwhile.
- Plan102 recheck OK after handoff/probe-correlation corrections. Current test-only
  display-poll stabilization keeps strict invariants;993 full serial tests and238
  independent focused release tests pass, scoped analyzer clean. No host changes,
  reloads, agent controls or TTL changes were used for code54.
- Code55: final full App1061 retained; fresh independent415 focused+49 two-machine
  matrix passes and scoped analyzer clean. Final review OK after intentional-socket
  handoff and authoritative snapshot-loss ABA corrections. Source648-file manifests,
  fresh AOT, same signer and byte-identical installed APK verified.
- Latest host B:294 focused,119 managed,1118 full passes/3 skips; complete Pi1.3
  snapshot, exact Sol/signed-loopback and modern async registry fixtures, no paid
  model turn. Whole package copy-verified/published at
  `~/.pi/agent/npm/node_modules/remote-pi/.releases/model-actions-59c3ca45c8186da9`.
  Later fresh ownership/native preflight found msg-bridge idle with no managed or
  background children; extension-only reload executed there, B imports observed.
  Main and mbot retained original PIDs/start ticks/ancestry. Owner API3 and actual
  phone new-model acceptance remain unverified; older A/releases retained.
- Code56 picker fix is built, **not installed**: bounded send/reply deadlines,
  correlated scoped errors/no history pollution, request-scoped caches and no stale
  model mutation/replay. Invalidated pickers require returning to sessions/reopening
  chat; their Close action cannot renew authority. Locked/unavailable access errors
  direct explicit actual-parent Check access. Existing API2 model actions remain
  supported; no Sol entry is fabricated for an old runtime.
  `app/build/releases/code56/accepted/code56.apk`, SHA256
  `b20cbca4f68e915101619c9d291f6fab29d274467d7056f532539868746d6dcb`.
  Same signer/fresh ARM64 AOT; current full1092 retained/hash-matched, independent
  release464 focused/analyzer clean. USB/paired mDNS unavailable; code55 remains
  the last verified installed app. No actual-phone spinner cause/repair is claimed.
- Receipts: ignored `app/build/releases/code55/accepted/` including public host
  provenance, install/pull proof and sanitized live-menu/info checks. Earlier failed
  attempt/logs retained; stale intermediate matrix marked historical, not reused.
  Code56/accepted holds current build and B publication/reload receipts; physical
  installation remains pending. See active plans103/105. Completed plans were removed
  at the operator's request (private backup retained); earlier plan references and
  removed-checkout paths are historical.

## Security limits

Lock revokes launcher/control/output/history access but leaves managed children
running. Shut down means stopping only this Owner's managed children and locking
access, never OS/Relay/another Owner's jobs. Neither operation rolls back work
already admitted.

Allowed filesystem roots are enforced, but selected model credentials are readable
by sandboxed project code, and network/local-service access remains available.
Relay TLS is not E2E; its operator can see transported content. Read the exact
contract and limits in `pi-extension/docs/secure-launcher.md`.
