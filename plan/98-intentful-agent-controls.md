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
- [ ] Final consumer review and full combined regression gate accepted.
- [ ] Exact-source App/host delivery and temporary-agent physical-phone Stop verified.
- [ ] Operator chooses local PIN and verifies approved-project launch on device.

## Evidence and limits

Host112 affected +29 routing tests preceded the cleanup fix; correction compiler,
build and69 affected tests pass. Primary RPC shutdown in cached SDK waits for a
subsequent command, so primary control is TUI-only; managed RPC children use the
parent-owned bounded stop path. No force-kill fallback for primary sessions.
Local `remote-pi-launcher` entry point now resolves installed setup CLI; it does
not set a PIN. Five approved folders remain registered; whole-home access stays
excluded. Runtime publication/device acceptance is not inferred from source.

## Next

Finish the delivery gates without adding a resident service or interrupting
unrelated processes; keep local setup and physical acceptance explicit.
