# 99 — Phone-first launcher setup and truthful presence

## Context

The operator reports inflated Online agents and cumbersome/nonworking phone launch
because the app requires PIN creation at the computer. They request implementation
using Pi Durable and confirm the Samsung is connected by ADB. This request explicitly
reopens plans97/98's local-only **initial** PIN setup requirement, not pairing,
existing-PIN recovery, registered-folder permissions or sandbox enforcement.

Current observations: Samsung SM_S926B, personal package
`io.github.asolopovas.remotepi.readable`, code50. Home screenshot shows Online3:
Mail Auth Setup (`mbot`), mbot (`mbot#2`), remote-pi. Local PIN file is absent;
five projects are registered. Registered metadata is not proof of launch readiness.
No source-backed Home arithmetic bug is established. Relay lacks heartbeat expiry;
this is a source defect candidate, not yet the verified cause of this phone count.

## Expected structure

- Pi Durable scoped writers and independent review; one writer per checkout.
- Host create-only `launcher_pin_initialize` through current authenticated paired
  root host channel, never managed-child ingress. Existing verifiers (including
  corrupt/unsafe files) cannot be replaced remotely.
- Add optional status `pin_setup: available|configured|unavailable`; absent means
  old-host unsupported. Available requires confirmed safe absence, not parse failure.
- Phone Create PIN/confirm → normal unlock → existing registered project selection
  → confirmed Start. No local terminal command for initial setup on supported hosts.
- Mutation has bounded request history/single-flight and transactional storage;
  recheck pairing, lifecycle/channel, incarnation/epoch around derivation/commit.
  Successful setup remains locked and rotates epoch. Never retain PIN payload,
  journal/history/log it, auto-unlock or replay after uncertainty. TLS remains
  non-E2E; relay operator is in the existing trust boundary.
- Keep project registry/sandbox/credentials requirements and existing Lock semantics.
- Correlate actual room/process identities before production presence changes.
  Never hide real distinct same-cwd agents with heuristic deduplication.

## Steps and acceptance

1. Host create-only initialization, strict codec, guarded transport and deterministic
   security/storage/race tests. Run isolated-HOME compiler/build/affected tests in
   `pi-extension/`; no real PIN, pairing or live reload during implementation.
2. App consumes exact additive contract with old-host fallback, matching/cleared
   inputs, explicit mutation, lost-response reconciliation and no automatic replay.
   Run analyzer and focused/full tests in `app/`.
3. Independent fresh security/lifecycle review; resolve concrete findings before
   runtime delivery. Produce same-signer higher-code ARM64 APK and verify actual
   packaged current source; preserve data with in-place ADB installation.
4. Same-window Home/room/process comparison, including Durable worker markers.
   Correct proven stale-presence/admission defects with bounded regressions; deploy
   only reviewed scoped changes without interrupting unrelated live agents/services.
5. Physical Home/setup screen acceptance on Samsung. User privately chooses their
   PIN; do not invent/type/capture it. Distinguish setup visibility from actual
   launch→discovery→chat→stop acceptance. Any remaining local host prerequisites
   must be reported exactly, not bypassed.

## Definition of Done

- [x] Initial PIN can be created from paired phone; existing PIN cannot be overwritten (source/tests; physical creation awaits user's private PIN).
- [x] Security, unknown-result, compatibility and lifecycle regressions pass.
- [x] Independent review accepted and correction gates complete.
- [x] Current Online evidence correlated; DSA_EXEC admission correction passes focused tests (fresh runtime worker check recorded below).
- [x] Reviewed host/App delivered without pairing loss or active-job restart; only an idle root's extensions were reloaded.
- [ ] Complete physical PIN creation → unlock → project launch → chat → Stop with operator-chosen PIN.

## Delivery evidence — 2026-10-17

Pi Durable workflow `01M55CFX7QSV5XQ6947BS6J4CB` implemented Host then App,
followed by independent review **OK with notes / no issues**. Source stays
uncommitted. Host passed typecheck/build,160 affected tests and34 focused routing
cases; App passed114 focused and894 full tests, scoped lib/test analysis clean.
Independent release gate `01M55DT86X61BZED8ERRCTRNTS` repeated compiler/build,
24 launcher plus34 routing tests and all894 App tests;628 source hashes unchanged.
One unchanged auxiliary pi-lens finding at secure_launcher.ts31 is not a compiler
error; LSP coverage was incomplete and is not called all-clean. Isolated pnpm
bootstrapped its executable despite a no-download constraint; no project dependencies
or source changed, and the Android build stayed offline. This breach is retained.

Personal Samsung package now code51, same signer
`44dc580c702f2757fb296c989608dad2826e12e771cc7e4364d50bd587c8516a`.
APK `app/build/releases/code51/code51.apk`, SHA256
`aa43d6b5f56f9ab36a588658f77a3b091f6ec09acc755cbe0a84d630d7e113d6`.
Actual installed APK pullback is byte-identical; UID10054 and first-install time
2026-10-11 00:11:47 unchanged. Fresh stripped AOT matches packaged libapp.so.

Current process/room correlation established two ordinary roots (mbot/ntinue)
and an extra live Durable child, not a zombie or Home arithmetic defect. Durable
uses DSA_EXEC while old producer checked only PI_SUBAGENT_CHILD. New automatic
admission suppresses DSA_EXEC workers, preserving mesh/manual opt-in and deliberate
phone-managed launches. Old already-running children are not killed/reloaded;
currently visible mbot#3 is such an old Durable child (PID1063313 at observation).
No Relay deployment/heartbeat change was necessary or performed.

Host installation first atomically exchanged all189 compiled files, preserving
original files under `~/.pi/remote/backups/remote-pi-host-20261017-182342`.
An idle mbot `/reload` at unchanged JS paths still served the old contract.
Read-only Durable oracle `01M55EJX08BMH0B9VYYW0ZCVRY` confirmed Node native-ESM
caching survives Jiti moduleCache:false and ordinary factory-cache clearing.
Rather than restart a working agent, runtime publication now uses immutable full
package root `.releases/phone-first-67a7bb6eb0b6e48c` within installed remote-pi.
Its189 dist files and23130 copied cached dependency files hash-match source;
all765 dependency symlinks remain within that copied tree. Skills/package metadata
are preserved. Only installed pi.extensions points at the versioned dist; npm
identity, source manifest, settings, pairing and PIN storage are unchanged. Keep
this root while any session uses it. Original installed manifest is backed up.
Before manifest activation, an isolated synthetic-credential real bubblewrap/Pi
RPC startup through this exact immutable layout passed, no prompts/provider or
production Relay calls. This verifies dependency resolution, not real project
readiness. No source dependency or network install was used for that publication.

After verifying the same native mbot session was idle, removed only stale queue
receipt q10 and queued one reload q11 for the new entry path. Reopened the phone
launcher on **Mail Authentication Setup** (room mbot); actual phone now renders
Create PIN/Confirm PIN, establishing live `pin_setup:available` capability. No PIN
was typed, invented, captured or read. Other existing sessions need their own safe
reload before supporting new setup; new processes load the new entry immediately.
Screenshots were taken only with empty PIN inputs. User must privately create and
unlock before real project-launch acceptance. Local credential/sandbox/project-tree
prerequisites remain enforced, not bypassed.

Final read-only Durable runtime check `01M55EWNYEJTR2QMAEBA3CFAEG` verified its
own PID1112588 with DSA_EXEC, same immutable manifest entry, and local broker/lock
identity ntinue#2. It had **no own established IPv4/IPv6 Relay connection**, while
both ordinary roots retained theirs. Old child1063313 remained connected and was
untouched. This independently verifies new-worker admission behavior; no Relay
inventory was queried and no claim of inspecting its in-memory module graph is made.
No phone/PIN/storage inspection occurred in that check.

A final read-only registered-tree metadata scan (no contents, credentials or PIN)
passes dotfiles25141 entries, ai-pc1095, mbot30290, msg-bridge644. The remote-pi
whole checkout reaches its existing elapsed/preflight bound at67614 entries and
remains blocked; no limit was weakened, files removed, folders re-registered or
private checkout invented to bypass it. The phone can use the four passing
registered trees; actual complete launch still needs PIN/credential/runtime gates.
This cutoff is not a lasting certificate against concurrent project mutations.
The selected global default openai-codex/gpt-6.1-sol is absent from cached0.79.10
model catalog; inspected SDK model-resolver falls back to available stored-provider
models. No actual provider turn or assertion of matching custom model availability
was made. Model selection remains available through the existing phone controls.

Receipts and logs: ignored `app/build/releases/code51/`.

## Next

Complete physical launch after the user's private PIN entry. Any durable supervisor
replacement for current session-owned managed children is separate architecture
work, not implied by using Pi Durable for this implementation.
