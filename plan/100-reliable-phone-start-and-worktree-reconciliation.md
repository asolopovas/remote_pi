# 100 — Reliable phone Start, Intent UX, and checkout reconciliation

## Context

Operator reports actual Start failure: "Could not start Pi; verify that pi is on
PATH and the extension is built" after plan99 delivery. They request installing
and applying the Intent skill to Start agent, less cumbersome PIN creation, ADB
verification, Pi Durable execution, and reconciling/removing unnecessary Pi-related
folders under ~/src. Earlier source/component success is not real launch acceptance.

Intent foundation installed at ~/.agents/skills/intent from ghaida/intent (HEAD
observed 3fc38dff381ce0e4dec8f52c97c3e37abd95e10e). Apply its evidence-led,
phone-first flow and actionable recovery principles; avoid cosmetic-only fixes.
Existing paired Samsung is the actual target. PINs remain private: never capture,
log, type or ask the operator to send one. Existing uncommitted plan99 work must
be preserved. User-created projects/new folders are not disposable by name alone.

## Expected structure

- Durable read-only diagnosis: exact failure stage/runtime cause, current phone
  state without PIN capture, and Pi-related worktree/references/process inventory.
- Intent UX context: one person controlling paired local Pi from a Samsung, without
  switching to the computer. Goal: choose project, authorize once, Start, see actual
  running agent or specific recoverable reason. Existing theme/security conventions.
- Scoped source writer(s) fix demonstrated producer/consumer defects, improve PIN
  flow and stage-specific recovery. No default PIN, stored plaintext, weakened
  allowlist/sandbox, credential leakage or unknown-mutation automatic retry.
- If initial creation is the friction source, explicitly reconsider plan99's
  create→normal unlock third entry: a create-only operation may grant ONLY the
  initiating currently paired Owner after validated publication, under existing
  lifecycle/epoch/Lock/revocation rules. Decide from evidence and review, not a
  silent blanket removal of PIN protection. Preserve old-host compatibility.
- Reconciliation: inventory clean/dirty status, history inclusion/unique commits,
  live processes/config/runtime/symlink references before removal. Integrate any
  necessary work first; preserve branches/commits and dirty/untracked work. Remove
  only independently established obsolete task worktrees with safe git worktree
  removal, never force/reset/prune arbitrary folders.

## Approved evidence-led direction

Intent assessment confirms a third PIN entry after Create+Confirm, no direct
navigation to the new agent, and generic error recovery. Implement create+confirm
→ **Create PIN & unlock** → project picker, granting only the initiating paired
Owner after successful create-only publication plus final authority rechecks.
This explicitly supersedes plan99's configured-but-locked creation response; older
hosts returning locked remain supported without retaining/reusing the PIN.

Source diagnosis reproduced a complete immutable-layout real managed launch with
synthetic loopback Relay and reproduced the exact generic PATH/build error using
synthetic unsafe auth-file permissions. Actual auth metadata is private0600;
therefore do not claim that fixture is the real phone failure. Subsequent actual
read-only prerequisite inspection established the real defect: host
~/.pi/agent/settings.json is a symlink to ~/.agents/pi/settings.json (regular,
user-owned,0664, bounded). open(O_NOFOLLOW) returns ELOOP, exactly the untyped
settings-read path in launch_sandbox that becomes the generic message. Support
this normal dotfiles setup by resolving the fixed known settings path and opening
its canonical final regular file with O_NOFOLLOW/descriptor checks; copy only
validated provider/model metadata. Keep secret auth.json nonsymlink/private0600;
never follow remote-supplied paths or expose raw settings/resources/secrets.
Reproduce red→green with synthetic symlinked settings in a full managed launch.
Classify known runtime/credential/preparation failures into fixed, safe actionable
errors; add optional launcher API/version metadata so old vs updated host selection
is observable.
Display actual host session as well as machine, and open only the confirmed running
agent's exact returned room. Never navigate on failed or unknown results.

Cleanup audit found six source-redundant task worktrees, no separate ~/src/pi.
Preserve any ignored local configuration/keys outside build/dependency caches in
private backup before removing clean/inactive worktrees; branches remain. Audit
ignored .pi and signing metadata filenames without printing secret contents first.
Unrelated or ambiguously user-created directories stay untouched.

## Steps and acceptance

1. Establish actual startup failure cause with reproducible regression; improve
   error classification without exposing raw credential-bearing stderr.
2. Apply Intent to PIN/project/Start/loading/error states with explicit phone
   recovery; test keyboard/actions/clearing, reconnect, compatibility and uncertainty.
3. Validate real installed-layout sandbox/Pi lifecycle, then independent review,
   current-source host/App builds and signed in-place Samsung update.
4. Prove actual phone launch/discovery/control/Stop when authorization permits;
   do not substitute get_state startup or source tests for a complete managed launch.
5. Audit and reconcile Pi task checkouts; delete only verified redundant/inactive
   clean worktrees, retain any uncertainty with exact reason. Record resulting paths.

## Definition of Done

- [x] Actual Start failure reproduced and corrected with regression coverage.
- [x] Intent-guided PIN/Start flow has fewer repeated actions and useful recovery.
- [x] Security/lifecycle review accepted; source/component host/App verification complete.
- [ ] Complete actual-phone Start → exact-room chat → Stop after private unlock (code52 delivered; API2 verified).
- [x] Pi folders reconciled; only proven unnecessary task worktrees removed.

## Delivery and cleanup evidence — 2026-10-17

Durable implementation `01M55QKX86YX7SVBCM7YW8XEGY` completed serial Host/App
writers and independent **OK with notes/no issues** review. Source stays uncommitted
and all plan99 work is retained. Host120 affected tests/compiler/build pass; full
App912 tests and scoped analyzer pass. A full exact-installed-layout real
bubblewrap/Pi fixture reproduces symlink-settings failure red→green, verifies
loopback Ed25519 challenge signing, creation grant, running→Stop, and unchanged0664
settings. No production credential/PIN contents, provider turn or live Relay were
used in that fixture.

Durable delivery `01M55RSW5RD03T6YC2D57YX0K1` removed all six audited obsolete
worktrees with normal git worktree remove, no force/branch deletion. Main branch,
HEAD, dirty diff/status and all tracked/nonignored-untracked hashes unchanged;
all six original branch refs remain. Unlinked only the two exact worktree dependency
symlinks, never the main target. Six local config files preserved byte-for-byte
under private0700/0600 backup
`~/.pi/remote/backups/obsolete-remote-pi-worktrees-20261017T202838Z-K7BmKH/`.
Its `backup-receipt.json` records verification. No ambiguous/unrelated folder was
removed; no separate ~/src/pi existed. Accessible activity checks passed, but
1973 denied operations per scan limit the claim to visible processes. Live runtime
releases/backups stayed out of cleanup. Only main remains in git worktree list.

Packaging source630-file snapshot unchanged, gradlew restored exactly,114 independent
host tests and202 focused App tests pass, scoped analyzer clean. Prior912 full log
retained, not mislabeled independent full rerun. Active LSP probes reported no
findings but all five were inconclusive, not all-clean. Initial cached pnpm shim
attempted an automatic install check; blocked network, no completed install/download
observed. Final gates used cached native pnpm with dependency checking disabled.
Attempt evidence retained, not described as never attempted.

APK `app/build/releases/code52/code52.apk`, SHA256
`837839b3ef624be57e5ddff68321299aaf52c53c651696486d25f99cf66bab16`;
ARM64 version1.2.0/code52, nondebuggable, same signer
`44dc580c702f2757fb296c989608dad2826e12e771cc7e4364d50bd587c8516a`.
Physical Samsung in-place installation succeeded; pulled installed bytes match APK,
UID10054 and original install time2026-10-11 00:11:47 preserved.

Complete immutable host package published at installed remote-pi
`.releases/phone-start-31679df93aa74980`:23331 files plus765 internal symlinks
hash/target-match private staged root. Full cached dependency tree preserved; no
live secrets copied. Old active release kept. Atomically changed only installed
manifest entry, backup
`~/.pi/remote/backups/remote-pi-host-plan100-20261017-213511/package.json`.
After native-ID verification of idle mbot root (no native subagents/queued work),
queued one idle reload q12. Actual phone launcher now shows **Launcher API2** and
session **Media and Enrolment Updates**, proving updated producer response on that
selected root. The coordinator's own busy root was not interrupted: q13 queues
one reload for its next idle boundary only; activation is not yet verified.
Verified-success mbot q12's stale queue receipt was removed, not resent. Phone is
at ordinary Unlock because operator already has a PIN; no reset/overwrite/new PIN
was invented.

Only sanitized accessibility labels were retained; editable/password nodes were
omitted, no raw hierarchy/PIN/screenshot retained. Actual production launch must
wait for the operator to privately Unlock; no authentication bypass is used to
convert source/fixture success into a physical claim. Receipts:
`app/build/releases/code52/` (ignored). SECURE-LAUNCH.md now references current
source/runtime/APK instead of deleted historical checkouts.

## Next

Privately unlock the already-open API2 phone launcher; then verify one fresh
registered-project launch, exact-room chat, and confirmed Stop without model turns
or touching existing jobs. Keep unrelated mailauth/other-agent work and live hosts
intact. Existing project-tree caps and model-credential protections remain enforced.
