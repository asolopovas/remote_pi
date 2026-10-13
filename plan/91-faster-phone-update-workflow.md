# 91 — Faster serial phone updates

## Context

User asks why delivery is slow and requests workflow improvements. The observed delivery took about six minutes, while compilation took 88 seconds. Preparation, artifact/source verification, install/smoke and agent coordination account for the remainder; per-stage timing was not recorded, so no finer attribution or speedup claim is justified. The worker adapted private build/evidence scripts and corrected two avoidable evidence-script issues (DEX text encoding and adb shell quoting). Prior runs copied entire private Gradle/stage/runtime trees for each version.

Code36 is already installed and independently verified. Do not launch another build or rewrite app features just to optimize this delivery.

## Expected structure

Coordinator changes apply to subsequent updates. Reuse the now-verified code36 build/prepare/verify/smoke lane instead of prompting each builder to recreate validators. Any durable helper implementation belongs to the App worker, never root. App source has one owner; updates remain serial and historical APKs/manifests/reports remain immutable.

## Steps and acceptance

1. Send a compact source-accepted handoff: input manifest/hash, installed target identity, next version, existing recipe path and only new constraints. One parent source review and affected tests; do not rerun unchanged suites or repeat instruction/repository discovery during delivery.
2. Reuse tested build/verification/smoke scripts with version/output parameters. Preserve the already-correct DEX encoding and remote-shell quoting. Retain strict failure handling; do not recreate equivalent ad-hoc Python helpers for each build.
3. Prefer one exclusive warmed build workspace/cache with hash-checked current-source synchronization, while archiving immutable per-version APK/manifests/logs separately. Do not fork multi-gigabyte caches by default. This requires an explicit reusable-workspace implementation/validation before changing the existing private-snapshot lane; it is not permission to overwrite historical evidence.
4. Perform one artifact gate before installation: frozen source membership/changed compiler closure, actual fresh packaged AOT, package/version/ABI/certificate, native plugin baseline. If native source and actual packaged DEX are byte-identical to a verified baseline, reuse that baseline proof instead of reparsing DEX. Parent cross-checks artifact/source identity without rerunning the entire builder's gate.
5. After targeted in-place install, check actual installed version/digest, launch and bounded crash smoke. Do not rerun full source/compiler checks after install when the same frozen snapshot and artifact remain unchanged; use a lightweight drift/identity check. Preserve signer, app data, physical-device targeting and no-microphone/privacy boundaries.
6. Record setup/build/gate/install/smoke/report elapsed times separately. Compare real subsequent runs before claiming savings; the only measured compilation baseline is 88 seconds, not a guaranteed end-to-end target.

## Definition of Done

- [x] Delay and avoidable repeated-work mechanisms identified from the current authorized task; no acoustic/layout claims or unmeasured speedup claims.
- [x] Compact handoff, affected-only validation, script reuse and baseline-aware checks selected for subsequent delivery prompts.
- [ ] Reusable parameterized App update helper/workspace validated, if implemented.
- [ ] A subsequent update reports per-stage timing and demonstrated end-to-end improvement without reducing install safety.

## Next plans

Apply the lighter coordination contract on the next requested App update. No extra deployment or worker is launched solely for this optimization discussion.
