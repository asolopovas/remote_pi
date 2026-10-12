# 84 — Repair primary-agent presence and verify personal Android delivery

## Context

The user reports an incorrect online Pi agent count, requested ADB inspection, then explicitly authorized fixes, validation, commit/push and installation on their device. The user additionally authorized isolated native Pi workers because Cockpit/cmux are unavailable. Root remains planning/integration/publication-only; implementation and subproject validation belong to scoped workers.

At the initial metadata-only checkpoint the Samsung SM_S926B (`R5CXB2PGC2H`) runs the personal fork `io.github.asolopovas.remotepi.readable`, version1.2.0/code29. Home reports Relay Connected / All15 / Online2 / Offline13, with mbot and remote-pi online. Foreground refresh leaves Online2. A primary Pi process in `/home/andrius/dotfiles` is running but absent from this coordinator's mesh roster and has no connection to the relay endpoint used by the two visible roots. This is a registration/connectivity discrepancy, not yet proof of faulty App arithmetic or its cause. Other newly observed runtimes must be classified by metadata, not counted automatically.

Baseline source is `3ff9f636` on `readable-android-fonts`, fork remote `origin`. Existing Extension edits continue changing and are not owned by this task; preserve them, isolate writers, and do not stage or publish another task's work. Initial status/diff and ADB evidence are private under `/tmp/remote-pi-presence-*`.

## Expected structure and ownership

- Coordinator: root plan, source/provenance review, component contracts, ADB, safe runtime activation, exact-file commit and push to origin (never upstream/force).
- Extension diagnostic lane: read-only causal diagnosis of missing primary registration, installed/source/API provenance and safe recovery. A future exclusive isolated writer owns only the accepted lifecycle/registration seam.
- App diagnostic lane: read-only presence/snapshot/reconnect audit plus repeatable personal APK build/signature path. App code changes require a concrete reachable count failure; a future exclusive isolated App worker owns only accepted changes and release metadata/build.
- Review: fresh read-only review of accepted source changes and exact validation outputs before integration/deployment/publication.
- Existing pairing, cached rooms, preferences, signing identity and app data must survive. No foreign transcript inspection, agent prompts, broad package upgrades, unrelated redesign or interrupting busy agents.

## Steps and acceptance

1. Establish the causal boundary using bounded metadata and source references. Separate running primary roots, managed children, intentional relay-off/print hosts and disconnected roots. Do not claim host-process count equals relay count. No source mutation during scouting.
2. Record the accepted single-seam or multi-seam lane board before writers. Use worktrees outside the primary dirty checkout and extension auto-discovery. Preserve source snapshots and no-commit worker policy; stop on infrastructure/ownership/contract blockers rather than silently switching execution modes.
3. Implement only evidence-backed registration/presence failures, with deterministic regression tests. Preserve automatic-child relay suppression, explicit manual opt-in, local mesh/locks, lifecycle generations and reconnect cancellation. Any App consumer correction must match the real Relay contract.
4. Validate exact source: focused regressions, component type/analyzer checks and applicable full suites with explicit pre-existing/environment exclusions. Independently review the diff and evidence; apply valid findings through the sole writer.
5. Build an incremental personal APK using the existing package/activity/signer, greater installed versionCode and unchanged pairing/settings. Use cached toolchains/dependencies; record source closure, APK hash, certificate, version and ABI. No unrelated synthetic/test entrypoint or mixed dirty-source build.
6. Safely activate only reviewed runtime artifacts with backup/provenance and rollback. Do not reload/restart a busy Pi session. Recover a current disconnected primary only through an explicitly safe lifecycle path; report any remaining activation gate honestly.
7. Install in place (`adb install -r`) on the named physical device. Inspect Home live presence at a shared metadata cutoff, foreground/reconnect behavior and fresh process logs. Verify ordinary primary visibility and automatic-child exclusion without foreign chat prompts or manufactured agents. Screenshots/processes alone are not proof of prevention.
8. Integrate only accepted worker changes without overwriting existing work. Inspect staged exact-file diff for unintended files/secrets, commit and push current fork branch without force. Confirm remote commit and artifact/source correspondence. No GitHub release publication is required by this request.

## Definition of Done

- [ ] Missing-primary cause established and bounded correction accepted.
- [ ] Deterministic presence/lifecycle regressions and component checks pass; limitations documented.
- [ ] Independent source/provenance review has no unresolved in-scope blocker.
- [ ] Reviewed runtime activation/recovery verified, or an exact remaining safe-activation blocker reported.
- [ ] Personal higher-version APK built from accepted source with matching installed signer.
- [ ] Physical-device in-place installation and presence/reconnect acceptance verified without data loss.
- [ ] Only accepted task changes committed and pushed to origin; remote identity checked.

## Fresh-perspective audit — 2026-10-12

Fresh metadata-only evidence is retained privately at `/tmp/remote-pi-fresh-audit.nehyL4/` (terminal roster, process/config metadata, socket ownership, Home accessibility snapshot and installed producer hash). No chat content was inspected, root restarted, pairing changed or subproject code/build mutated.

- Four ordinary interactive Pi processes are present: mbot, remote-pi and **two distinct dotfiles sessions**. None has print-mode flags, the managed-child marker, a daemon marker or an inline `REMOTE_PI_DIRECT_CONFIG` override. During the earlier checkpoint the fourth pane was `.agents`, blocked at the first-time Remote Pi name wizard; that process subsequently exited and the pane now hosts another dotfiles root. This moving roster must not be treated as one immutable snapshot.
- mbot and remote-pi have project-local Remote Pi config with `auto_start_relay:true`. Both own live mobile rooms. Physical phone Home still shows **Connected / All15 / Online2 / Offline13**, exactly those two rooms. Local `list_peers` contains mbot, with this coordinator intentionally omitted by that API.
- Neither dotfiles root has `/home/andrius/dotfiles/.pi/remote-pi/config.json`; that directory itself is absent. The **actual installed** Extension's `session_start` handler at `dist/index.js:2091–2117` invokes `_cmdRoot` only when `localConfigExists(cwd)` and effective autostart are true. `src/session/local_config.ts:114–128` confirms exact-cwd config or inline override only. Thus these roots never enter automatic mesh/Relay registration. This is an onboarding/autostart eligibility gap, not evidence of missed App snapshots or erroneous Online arithmetic.
- Installed producer index SHA256 remains `211cb0d22db2efe9ac5a81839fef0d8248e1d93e38aefdb18b2ee8e812631583`: managed-child suppression is present, but TUIOS display adapter and room-display endpoint are absent. Title synchronization therefore remains a **separate runtime-delivery gate** under plan81; an App rebuild cannot add missing producer behavior.

### Narrow recovery and acceptance

1. Enable Remote Pi once in dotfiles using its existing `/remote-pi` setup, preserving the shared machine identity, pairing and project-local autostart policy. Do not silently change global onboarding defaults or connect every unconfigured project. Both current dotfiles module instances then need their own idle-safe `/remote-pi` invocation; writing config alone does not rerun their already-emitted startup event. Existing cwd/name collision handling distinguishes the two rooms.
2. Do not inject commands, reload or restart the working dotfiles agents. Coordinate an idle-safe activation with the operator; waiting for safe activation is a real gate, not a source-code blocker.
3. Recheck terminal/native IDs, registered room IDs and phone Home in one bounded observation window. Expect one mobile room per opted-in ordinary root, including both dotfiles roots if both remain live; do not use cwd deduplication or process-count filtering. Retain offline cached rooms and managed-child suppression. Future dotfiles startups should auto-register from the persisted config.
4. A registration-only recovery needs **no App change, APK rebuild, dependency download or source commit**. The broader plan's APK/publication steps apply only if a separately evidenced source/release correction remains necessary. Name synchronization still needs the separately reviewed Extension runtime closure and safe loading; no completion is claimed here.

The old plan81 producer run is discoverable by native status and has fresh private build evidence, but a cross-session steer returned `not found in the active session`. No replacement writer or CLI fallback was launched, and partial artifacts are not treated as a completed/reviewed activation handoff.

## Next plans

Existing native-history/admission/display work (plans77/80/81) remains separately scoped unless a concrete dependency blocks this presence repair. This task does not certify all conversations fresh or all monorepo products built.
