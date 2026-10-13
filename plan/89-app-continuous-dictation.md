# 89 — Continuous dictation until explicit Stop

## Context

The user reports dictation stops automatically and requests live transcription until pressing Stop. This supersedes plan29/76's whole-session 60-second cap. Native recognizers can still end individual segments on silence, final results or platform limits; the app must manage successive segments rather than pretend one native listen is indefinite.

Retain tap-to-start/Stop, live composer text, manual Send, on-device recognition, permissions and final-word retention. Backgrounding, leaving the chat, cancellation/disposal and genuine errors must release the microphone safely.

## Expected structure

One App writer owns the coupled speech-service/voice-viewmodel lifecycle, minimal composer changes and focused tests. Root owns planning/review. Narrow Darwin vendor task/generation guards protect callback entry, queued Flutter delivery and delayed cleanup, retaining valid Stop-time finals/errors. No provider/dependency/SDK changes.

## Steps and acceptance

1. Reproduce premature completion in focused tests. Distinguish normal native segment ends from fatal errors.
2. Serially finalize, retain and restart normal segments while user intent remains active. Correct partials replace the current segment only; earlier final text remains intact. Remove the whole-session cap, retain bounded finalization and positive restart pacing. Show reconnecting truthfully and stop visibly if restart fails.
3. Explicit Stop revokes restart intent synchronously and retains final words. Fence rapid taps, asynchronous startup, late callbacks, pending restarts, cancellation/disposal, backgrounding and room changes by session/segment identity. Never auto-send.
4. Test multiple segments, silence, the former cap, partial corrections, final/status/error ordering, failed restart, Stop during transitions and lifecycle teardown. Run scoped formatting, analysis and affected service/VM/composer tests from App.
5. Review source before fresh real-main ARM64 packaging. Verify source/compiler/packaged-AOT identity, package/activity/signer and higher version before targeted in-place installation. Never uninstall, clear data or change microphone permissions for delivery.

## Validation and limitations

121 affected host tests passed; scoped Dart analysis, formatting and diff checks passed. Active LSP checks were inconclusive. Apple native compilation/runtime is unavailable on the Linux host; Darwin tests cover Dart behavior and source fences, not Apple runtime proof. Native finalization/restart gaps may miss spoken words.

The Android fix was delivered in build35 and retained in build36, with verified artifact/source identity and in-place installation. Human acoustic/multi-phrase/Stop acceptance remains separate.

## Definition of Done

- [x] Explicit continuous-until-Stop behavior supersedes the whole-session cap.
- [x] Normal native segment ends preserve user intent and accumulated text (source/host proof).
- [x] Stop and lifecycle/error teardown prevent restart and preserve final words (source/host proof).
- [x] Focused tests/analysis and parent source review pass; platform limits recorded.
- [x] Verified Android update delivered without uninstall/data clearing.
- [ ] Human verifies multi-phrase dictation and explicit Stop.

## Next plans

Plan90 adds the persisted wrap default. Plan87's benign-error classification alone is not continuous-dictation acceptance.
