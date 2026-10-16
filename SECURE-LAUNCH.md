# Secure phone project launcher — setup

Implemented on branch `feature/pin-project-launch` in this isolated checkout.
Original `/home/andrius/src/remote-pi` voice/composer work and active agents were not changed.

## Delivered

- Restored owned Relay: `https://173.208.50.216` / `wss://173.208.50.216`, trusted TLS1.3 and renewal/check timers verified.
- Home header Refresh requests current discovery without reconnecting/changing selection.
- Phone Start agent flow: PIN unlock, registered project picker/allowed folders, fresh background Pi, own managed Stop, Lock and confirmed owner-only Shut down.
- Local registry CLI, hidden PIN setup, host-enforced grants/cooldowns, Linux filesystem sandbox and parent-owned child room transport.
- Lock leaves agents running but revokes control/output/history. Shut down stops only your launcher-managed children and globally locks access; never OS/Relay/another Owner's agents.

## Local setup (no PIN in command line or chat)

```sh
EXT=/home/andrius/src/remote-pi-secure-launch-integration/pi-extension
node "$EXT/dist/bin/launcher.js" pin-setup
node "$EXT/dist/bin/launcher.js" project-add 'My project' /absolute/project \
  --allow /absolute/project --allow /absolute/optional-extra-folder
node "$EXT/dist/bin/launcher.js" project-list
```

Choose your own6–12 digit PIN in the hidden local terminal prompt. Replace paths
with the exact projects/folders you authorize; do not run these placeholders.
Registry changes are local-only; the phone cannot register arbitrary folders.
Stored model credentials must already exist in local Pi auth.json; no default PIN,
model credential or folder permission was invented. See `pi-extension/docs/secure-launcher.md`.

Start a **new** launcher process from the intended launcher directory (do not reload
an active job). Use the project's cached Pi runtime validated by the sandbox tests:

```sh
REMOTE_PI_RELAY=https://173.208.50.216 \
REMOTE_PI_DIRECT_CONFIG='{"agent_name":"phone-launch-host","auto_start_relay":true}' \
node "$EXT/node_modules/@earendil-works/pi-coding-agent/dist/cli.js" \
  -e "$EXT/dist/index.js"
```

Select that exact paired host/session on the phone using the owned Relay. Existing
phone endpoints/pairings were not migrated automatically. Restored server storage
is new; reconcile missing membership explicitly through normal pairing/account
flows. Managed children use parent identity/rooms, not independent phone re-pairing.

Children survive phone disconnect, but stop when their launching host closes,
changes session or reloads. No initial prompt/inference is sent on Start.

## Android artifact

Reviewed ARM64 APK (46.0MB):

`/home/andrius/src/remote-pi-secure-launch-app/app/build/secure-launch/RemotePi-secure-launch-7bf3d2f2-arm64.apk`

SHA256: `28042eca47a02fb861c61b3c879dd3619f5f9eed21598ba5321dfa23381724f7`.
No physical phone was connected (only emulator5558); this APK was not installed.
It includes the reviewed App branch, not unrelated uncommitted voice changes.

## Validation and limits

App: initial835-test serial suite;436 affected correction tests and3 real socket/page
regressions; analyzer clean. Host:71 focused +27 affected tests, real bwrap/Pi/loopback
signature-verifying Relay/private pipe fixtures; compiler/build clean. Independent
reviews accept App7bf3d2f2, hostd14feb93 and final PIN-prompt fixd46eac06. Ten real
PTY hidden-input tests pass. Actual host result generation parses in Dart and all
seven Dart request serializers are accepted by host codec. Combined source matches
accepted component trees exactly; compiled integration build passes.

Nine existing host full-suite failures plus an unhandled rejection were reproduced
against the original baseline and left untouched; this is not an all-green claim.
Production phone-to-owned-Relay launch/control and operator-chosen setup are not yet
accepted. Synthetic test PINs existed only in temporary storage that was removed.

Linux sandbox denies unrestricted host folder access. Hardlinks, nested mounts,
special files, inaccessible or excessive registered trees fail closed; prepare any
needed private normal-file project copy locally, never weaken the gate. Selected
model credentials are readable by project code, and network/local-service access
remains available; this is filesystem isolation, not perfect isolation. Relay sees
transported content (not E2E). Lock does not erase previously disclosed metadata or
recall already admitted frames. Locked updates reveal working boolean only, no new
model/thinking strings. See durable component docs for exact limits.
