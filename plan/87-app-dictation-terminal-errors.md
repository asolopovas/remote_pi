# 87 — Dictation terminal error classification

## Context

The user reports dictation always ends with an error. Current InputBar shows “Dictation ended with an error. Review recognized text.” whenever VoiceFailed is emitted. SpeechToTextService's plugin adapter discards SpeechRecognitionError.errorMsg/permanent; every error callback marks the ViewModel capture failed. Cached Android plugin emits error_no_match/error_speech_timeout (and currently permanent:true for every emitted error). This is a plausible cause, not an established reproduction of the user's exact recognizer callback; exact error/text-retention evidence has been requested.

Preserve plan76 tap-toggle, live cumulative composer text, bounded final-result waiting, on-device recognition, final-word retention, manual Send, no background microphone, scoped generation/cancel/dispose safeguards. Do not silence all errors merely because partial text exists.

## Expected structure

One fresh, bounded App voice worker: speech service/plugin seam, VoiceInputViewModel only if needed, focused existing speech/voice tests. No native/vendor/SDK/package/network/settings changes or model fallback. Root owns plan/Git; App owns source/checks and subsequent approved packaging.

## Steps and acceptance

1. Inspect cached native/plugin terminal/error contracts and existing service/VM tests. Preserve internal error identity instead of treating every event as an untyped void failure. Distinguish normal silence/no-match/end-after-stop from genuine permission/audio/recognizer/network/unavailable/unknown errors using documented codes and current lifecycle state. Do not infer benign behavior solely from permanent:false or from nonempty partial text.
2. Regression-test final/partial text followed by benign terminal errors, natural end/manual stop, final-result races, no-speech capture, genuine/unknown errors even after text, restart, cancellation/disposal/room-generation isolation. Preserve truthful UI and recognized draft; never send text automatically. Test captures contain synthetic phrases only, not user dictation.
3. Format/scoped cached analysis and only affected voice/service/input widget tests. Report actual fix and limitations concisely at a native source-acceptance checkpoint. Root reviews exact diff/tests before publishing or granting the same worker the serial build/device lane; no redundant scouts/full suites or unrelated history reports.
4. After source acceptance, commit/push and use the existing warmed code32 build recipe for a higher-version real-main ARM64 in-place Samsung update, unchanged package/activity/signer/data. No microphone capture/permission changes, synthetic speech, transcript logging, Settings edits or remote prompts. Actual human spoken-word/end-error verification requires the user's feedback; static/fake tests cannot prove acoustic/device behavior.

## Definition of Done

- [x] Recognizer error identity retained and terminal classification regression-tested. Internal SttError preserves code/permanent; only active error_no_match/error_speech_timeout end normally, with bounded final waiting retained. Other/client/audio/network/unknown errors remain failures even after stop or partial text.
- [x] Draft/final words and real failure visibility preserved; focused analysis/tests/direct parent source review accepted. Worker `90553d69-b6ed-4589-b28b-8ebe1c4c26de`: eight regressions failed before classification, 79 affected tests passed afterward, six-path analyzer clean. Exact four-file source/test hashes and diff checked by parent. Active LSP: one confirmed clean, three timed out; no all-path LSP claim. A pre-existing SoundLevelScale host assumption was made portable without changing production scaling. The user's actual recognizer error code remains unconfirmed.
- [ ] Accepted fix committed/pushed and higher-version APK installed without app-data changes.
- [ ] User verifies normal spoken dictation ends without the erroneous warning; exact-device limitation recorded if pending.

## Next plans

Plan85 session/history cleanup remains approved but unimplemented. No speech change is an implementation of cleanup.
