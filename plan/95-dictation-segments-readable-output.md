# 95 — Preserve dictation across phrases and reduce output clutter

## Context

The user still hears repeated disconnect sounds and loses dictation mid-conversation after plan89's successive-capture implementation. Source inspection confirms recognizer teardown/recreation at speech boundaries, a native/Dart 60-second cap and repeated native Stop calls. Those explain possible capture gaps; device tones themselves have not been reproduced or attributed acoustically.

The user also requests compact human-readable outputs instead of incidental JSON, with properly formatted code. Existing plan75 fixtures expose shell metadata and repeated codemode execution headers, while ordinary tool arguments and native edit arrays remain unnecessarily raw.

## Expected structure

The parent is the sole App writer, with read-only native-lifecycle diagnosis and independent voice review. Scope: vendored Android recognizer and Dart timer coordination, tool-output/argument presentation, existing tests and small focused regressions. No new dependencies, cloud recognition, stream muting, device microphone operation, permission changes or relay changes.

## Steps and acceptance

1. Request optional API33+ segmented on-device recognition using the documented silence selector and paired millisecond value. Preserve API31/32 and ignored-extra ordinary-result/error fallback.
2. Keep committed phrases plus replaceable current hypotheses in one native capture. Phrase finals remain nonterminal; terminal/Stop-time final seals the cumulative transcript. Preserve repeated legitimate phrases and capture/listener fencing.
3. Only an actual segmented callback proves support and removes both 60-second caps. Fence an early capability callback before listen acknowledgment. Keep provisional unsupported-provider finalization bounded; make Stop idempotent and disarm its cap synchronously. Retain real errors, explicit Stop, background/disposal release and manual Send.
4. Replace shell JSON metadata with output text and essential failure/truncation/full-output-path notices. Remove repeated codemode execution wrappers while preserving ordered section identities and unknown text. Show typed tool fields and edit diffs; retain raw details, exact source, syntax highlighting and copy/wrap/disclosure behavior.
5. Verify scoped Flutter tests, real Kotlin compilation/JVM lifecycle tests, formatting and analysis. Inspect host-rendered narrow/large-text output. Independent voice review precedes source acceptance. Acoustic/device acceptance remains separate from tests.

## Definition of Done

- [x] Optional segmented capture, cumulative phrase results and coordinated caps implemented.
- [x] Stop race, fallback, stale callbacks and synchronous capability regression-tested.
- [x] Human-readable tool fields/output and edit previews implemented with raw escape hatches.
- [x] Final focused tests/analysis and independent voice review pass.
- [x] Commit/push accepted fixes and install verified higher-version Android update in place.
- [ ] Human confirms continuous dictation, sounds and visual behavior on the handset.

## Validation and limitations

96 affected Flutter voice/service/composer tests and 59 output/rendering/viewport tests passed. Production Kotlin compiled and 261 JVM assertions passed. Independent review identified a provisional-watchdog/Stop deadline race: a new regression failed before the fix, passed afterward, and targeted re-review accepted the fix. Scoped Dart analysis reports no issues; formatting and diff checks pass. Active LSP confirmed three paths clean, with six timeouts; no all-path LSP claim. Host screenshots inspected at 320px/2x show compact warnings, preserved source formatting and collapsed raw details; this is not handset visual acceptance.

Segmented microphone-backed recognition is provider-dependent and is not a guarantee of silence or indefinite audio capture. Unsupported recognizers retain paced restart gaps. The verified update below is installed; acoustic/human dictation acceptance is not claimed.

## Delivery — build39

User requested commit/push followed by device installation. Source commit `7a0dc06fa81b529403bdb381370cf02176ddc701` pushed to `origin/readable-android-fonts`. Reused the warmed build38 lane in a new immutable `app/build/releases/code39/` archive, retaining historical evidence.

The fresh real-main release APK is `1.2.0/code39`, ARM64 App/engine, unchanged package/activity/minSDK/signing identity. SHA256: `d6c8641204361869436ced749cc4c7dc3de9909834053faa562a2ae47c9dc3b8`. Source membership/compiler closure/cache hashes and stripped fresh AOT matched the actual APK. Updated native DEX was revalidated rather than falsely reusing build38's native baseline: both segmented callbacks are on the patched capture listener, two on-device factory calls and zero generic/cloud factory calls, with plugin registration retained.

Physical Samsung `R5CXB2PGC2H` updated from38 to39 via targeted `adb install -r --user 0`: Success. Pulled installed base APK matches the candidate byte-for-byte; app ID10054 and first-install time remain unchanged. Existing app launched successfully and stayed alive for the 12-second crash-only smoke with zero crash entries. No uninstall/data clear, microphone capture, transcript logging or permission/settings changes.

Measured stages: setup0.2s, compilation71.8s, artifact gate1.7s, installation/identity4s, crash smoke12s. These are stage measurements, not a claim about overall coordination time or comparable end-to-end speedup.

## Next plans

Collect human spoken multi-phrase/Stop feedback without recording or logging private dictation.
