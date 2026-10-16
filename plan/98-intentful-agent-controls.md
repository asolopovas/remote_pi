# 98 — Intentful creation and exact running-agent Stop

## Context

Operator reports a dead/cluttered Start form: no selectable projects, disabled
PIN, optional name, Lock/aggregate shutdown and a misleading Managed agents
heading. Host has five approved project folders but no locally chosen PIN.
Separately, the operator wants to stop a running agent, not merely close chat.
Do not invent a PIN or weaken the registered-project/managed-child grant gate.

## Expected structure

- App creation states: connecting → local host setup if absent → editable PIN
  unlock → approved-project radio list → confirmed Start. No freeform folder or
  name, dead form, management section or aggregate shutdown in creation.
- Secondary owned-agent management/access locking. Session info X dismisses
  info; Stop agent is a distinct confirmed process control, not view navigation.
- Additive opaque `session_control_status`/`session_stop` contract in
  `pi-extension/docs/session-control.md`; paired exact-room one-use capabilities.
  Root native SDK identity/lifecycle and managed immutable process/grant scopes
  remain separate. No arbitrary PID, shell, OS/Relay stop or mutation replay.
- Control replies/errors bypass chat/history. Requested ≠ actual stopped.

## Steps and acceptance

1. Rebuild native creation flow with 16px spacing, explicit prerequisites and
   radio selection; test locked/setup/expiry/cooldown/project-definition races.
2. Implement and test host and App exact-session stop; prove stale room/Owner,
   lifecycle/native/context/token replay/grant failures cannot close another Pi.
3. Review producer/consumer independently. Managed deferred-cleanup regression
   reproduced red before correction; captured capability now owns finish cleanup.
4. Validate component and real ingress/no-history boundaries; build/install a
   same-signer higher-version update without data clearing.
5. Test only a temporary agent for real Stop, never an existing active job. Real
   project-launch acceptance still needs an operator-chosen local PIN.

## Definition of Done

- [x] Host implementation integrated with strict codec and scoped capability tests.
- [x] Host fresh review finding corrected; targeted recheck OK (e82d2384).
- [x] Creation state flow and App stop consumer implemented; targeted125 tests and analyzer pass.
- [x] Final consumer review OK;875 full App tests/analyzer pass. Subsequent read-only control-refresh/30s client-expiry correction passes36 focused tests.
- [x] App50/host delivered; temporary primary TUI Pi stopped from the Samsung with exit0, returned Home, no model turns or unrelated agent stops.
- [ ] Operator chooses local PIN and verifies approved-project launch on device.

## Evidence and limits

Final host compiler/build,112 affected tests and29 targeted routing tests pass
(208 unrelated routing cases intentionally skipped). Cleanup regressions failed
before correction;69 focused correction tests pass. Final consumer review OK.
An old5ms room-stream test raced on a later full run; test-only correction awaits
actual announced/ended/snapshot emissions. Final whole suite875 and analyzer pass.
Production App inputs remain unchanged from installed e0ed6fac.

Primary RPC shutdown in cached SDK waits for a subsequent command, so primary control is TUI-only; managed RPC children use the
parent-owned bounded stop path. No force-kill fallback for primary sessions.
Local `remote-pi-launcher` entry point resolves installed setup CLI; it does not
set a PIN. Five approved folders remain registered; whole-home access stays
excluded. Samsung build50 was built from e0ed6fac, APK SHA256
`c53e12690a5a006a73a659c499ef037ef25019feace8627923db3d24c62f1bb6`;
byte-identical pullback, signing identity, app UID and original installation time
verified.189 compiled host files hash-match; backup at
`~/.pi/remote/backups/remote-pi-host-20261016-145941`.

Physical test used only temporary native-TUI process3058233, no prompts/model
messages, normal SDK exit0 and App returned Home with no unknown-result notice.
Its empty local cache/test directory were cleaned; the four prior online sessions
remained. Unconfigured-host screen has zero editable/disabled inputs and no old
name/management/shutdown clutter. Real authorized project selection/launch remains
unverified until the operator runs `remote-pi-launcher pin-setup` locally.

Idle-safe `/reload` updates were queued for four current approved-project Pi
windows. Two idle command deliveries did not produce an acknowledgement; busy
windows remain queued. Do not equate installed files or queued reload with all
existing live sessions loading the new producer. Later optional capability probe
was abandoned when the phone foreground changed to another app; no further phone
input or existing-process Stop was performed. QA receipts are in ignored
`app/build/releases/code50/`; no device key/PIN/token was captured in them.

## Next

Finish the delivery gates without adding a resident service or interrupting
unrelated processes; keep local setup and physical acceptance explicit.
