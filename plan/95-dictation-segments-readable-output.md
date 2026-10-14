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
- [ ] Human confirms continuous dictation, sounds and visual behavior on the handset.

## Validation and limitations

96 affected Flutter voice/service/composer tests and 59 output/rendering/viewport tests passed. Production Kotlin compiled and 261 JVM assertions passed. Independent review identified a provisional-watchdog/Stop deadline race: a new regression failed before the fix, passed afterward, and targeted re-review accepted the fix. Scoped Dart analysis reports no issues; formatting and diff checks pass. Active LSP confirmed three paths clean, with six timeouts; no all-path LSP claim. Host screenshots inspected at 320px/2x show compact warnings, preserved source formatting and collapsed raw details; this is not handset visual acceptance.

Segmented microphone-backed recognition is provider-dependent and is not a guarantee of silence or indefinite audio capture. Unsupported recognizers retain paced restart gaps. No phone update or acoustic test is claimed by this source change.

## Next plans

Deliver through the existing verified in-place Android workflow when requested, then collect human spoken multi-phrase/Stop feedback without recording or logging private dictation.
