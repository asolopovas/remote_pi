# 74 — Active client registration and mobile discovery recovery

## Context

User requests observing and fixing the installed Android app so all active clients appear. Device Samsung R5CXB2PGC2H, package `io.github.asolopovas.remotepi.readable`, 1.2.0/code20. ADB home capture shows All6/Online1/Offline5: only dotfiles is registered. Other running Pi sessions have no cwd Remote Pi configuration; this is not a proven Home filter defect.

Read-only diagnosis: `/tmp/74-client-discovery-diagnosis.md`. Existing `/remote-pi relay start` registers a current interactive session without setup/restart/re-pairing, using the machine identity and existing relay. Submit only when the original terminal is idle; never interrupt work or answer an approval. This does not join the local mesh or persist startup settings. No universal autostart policy change authorized by this repair.

A separate source-backed app defect can retain Offline after missed Pi pings, even after inbound recovery. Foreground resume also fails to reconcile rooms on an otherwise connected socket.

## Expected structure

App transport owns an idempotent read-only discovery refresh for existing authorized subscriptions. Application resume invokes it. Review found the current relay suppresses unchanged room snapshots, so a rooms_check alone cannot recover locally-degraded status. Revised App-only repair: a current-channel, latest-probe-correlated Pong may restore only the exact previously-authoritatively-live active room that this client marked degraded. Explicit room end/snapshot/selection/channel/subscription changes invalidate this authority. Arbitrary messages, unknown/cached-only rooms and stale Pongs never manufacture Online. Discovery refresh remains useful for registry changes; no relay deployment is required. Because PlainPeerChannel discards envelope provenance, the transport must enforce normalized expected sender Pi EPK on inner envelope ingress before any Pong can carry that authority. Keep the existing room guard and legacy expected-peer/no-room handling; relay control discovery for other subscribed PCs remains unaffected. Validate this boundary with a real local WebSocket regression.

## Steps and acceptance

1. Register missing current sessions using existing in-process slash command and exact discovered terminal IDs, queued at idle. Preserve identity/relay/Owner and leave existing online session untouched. Verify actual phone room rows, not merely command delivery.
2. App-only implementation: refresh presence and rooms for existing subscriptions on foreground resume and heartbeat recovery. Also restore a previously-live room's local heartbeat status after a verified current matching Pong, even when the unchanged snapshot is suppressed. No WS teardown, unsolicited subscriptions, message/history mutations, pairing changes, or new dependencies. Keep known offline cache/history and normal subscribe/reconnect semantics.
3. Deterministic regressions: model relay suppression of unchanged responses, then ping-degraded active room + current matching Pong recovers without manually injecting a snapshot; repeated normal inbound messages do not spam refresh; foreground reconciliation requests room state on connected transport; disconnected/empty subscriptions safe; ended/unknown rooms remain offline until authoritative announcement/snapshot.
4. Analyze, focused transport/Home/lifecycle tests, full suite with only existing documented platform-scale exclusion. Build compatible ARM64 release code21 from App cwd; compare code20 signer and package ID. Worker does not use ADB.
5. Parent installs compatible update in place and observes phone Home Online/All counts, background/resume, unchanged pairing/preferences and existing chat. Never uninstall, clear data, re-pair, submit an agent prompt, or stop running agents. Record which recovery cases were only host-tested.

## Definition of Done

- [x] Phone observation and installed/source diagnosis.
- [x] Current missing sessions actually announce on phone: code20 Home XML/screenshot records All10/Online5/Offline5, including ai-pc and remote-pi; each uses the existing pairing.
- [x] Revised App recovery/resume regressions pass against modeled relay dedup: 16 recovery/local-WebSocket tests, 115 focused and 594 full tests; analyzer clean. Initial snapshot-only candidate remains rejected.
- [x] Corrected exact candidate analyzer/tests/build/signature verified. Corrected code21 SHA256 6fe026d0c4ced043139f6e7e9fdd18725ff971d4e183dbbb7d8086e9ce57e770 matches exact source hashes and independently pulled device code20 signer/package; independent re-review returned OK with notes, no issues found. Rejected initial code21 SHA256 a0f9b495c400dd495222ab2ec467c57cbe7ef3d6dd77ade8561b0dcd8a4412d9 is preserved separately and must not be installed.
- [x] Compatible device update and observed Home/resume check.

## Device acceptance evidence

- In-place `adb -s R5CXB2PGC2H install -r app/build/74-discovery/code21.apk` succeeded; Android reports version1.2.0/code21 for the unchanged package. No uninstall, data clear, re-pair, submitted agent prompt, or agent restart/stop.
- Current App PID31519. Cold boot, background/Home then foreground resume, and final Home all show Relay Connected / All10 / Online3 / Offline7. Independent process/terminal inventory now has exactly three interactive Pi sessions: dotfiles PID2097557, ai-pc PID2469700 and remote-pi PID2542139. The two other previously visible sessions ended independently during the work; no fake Online5 expectation was imposed.
- `/tmp/74-code21-final-home.xml` asserts Online3 and all three current cwd rows; `/tmp/74-code21-final-home.png` records final screen. Resume capture `/tmp/74-code21-resumed.{xml,png}` has the same counts. Earlier missing-session remediation was already observed before the app update, not attributed to this patch.
- Existing ai-pc and remote-pi chats opened and rendered current natural transcripts/working status without prompting agents. Evidence `/tmp/74-code21-ai-pc.{xml,png}` and `/tmp/74-code21-remote-pi.{xml,png}`. Phone left on Home.
- Settings UI semantic values/selections compared exactly before/after update: unchanged relay, main-linux pairing, System theme, Large text, hide-tools off and collapse-subagents on. Evidence `/tmp/74-settings-before.xml` and `/tmp/74-code21-settings.{xml,png}`.
- Current-process log `/tmp/74-code21-device-log.txt`: 284 lines, zero matches for E/flutter, FATAL EXCEPTION, Null check operator used, RenderSliverMultiBoxAdaptor, childMainAxisPosition or Unhandled Exception. This is a scoped observation, not proof that all runtime paths are error-free.
- Heartbeat failure/recovery, relay unchanged-snapshot suppression, malformed/wrong senders and stale channels were deterministically host-tested, not artificially induced on the production phone or relay. LSP probe confirmed3/5 changed Dart paths clean with2 timeout/inconclusive; complete LSP coverage is not claimed. CLI analyzer and594-test suite passed.
- Worker implementation/correction evidence: `/tmp/74-app-discovery-recovery.md`; independent accepted re-review: `/tmp/74-app-discovery-review.md`. Changes remain unstaged and uncommitted.

## Next plans

Optional explicit machine-level startup consent for arbitrary future projects is a separate product/privacy decision, not a silent global default flip. Local mesh registration and per-project persisted configuration are separate from this live mobile repair.
