# 76 — Tap-toggle live dictation

## Context

The user explicitly requests: tapping the microphone immediately starts typing recognized words into the composer; tapping it again stops. Recognition currently loses/incompletely finishes words. This supersedes plan29 decisions4/6/11 (hold-to-talk, no live transcript, input-covering strip). Preserve plan29's manual Send, local-recognition preference, permission handling, locale fallback and bounded recording duration. Do not silently change recognition providers or send audio/text to an agent.

Observed implementation: InputBar._onVoiceTap only shows a hold hint; SpeechService accumulates partials privately; VoiceInputViewModel publishes text only after stop; recording overlay covers the composer. stop awaits native stop then immediately reads latest partial without explicit final/status handling. Callback/session races and native early termination require evidence, not guesses about ASR quality.

## Expected structure

One App writer, presentation/service capture lifecycle seam only. Speech service exposes bounded live transcript/capture lifecycle through its existing testable contract; viewmodel handles starting/listening/finalizing/idle and generation/disposal guards; input bar keeps the text visible and uses an unmistakable dictation toggle. Preserve existing queue, steering, agent Stop, attachment, hardware/IME and chat-room ownership behavior. No relay, extension, protocol or agent-settings edits. No new dependencies/downloads, recorded audio files, cloud fallback or SDK installs.

## Steps and acceptance

1. Reproduce tap-not-starting and live-text/final-result deficiencies with existing fake-plugin/service/composer tests before changing production. Read cached speech_to_text platform implementation to establish final callback/status semantics and current options; do not run recovered source fixtures.
2. Tap starts without a hold or artificial delay (native initialization/permission are honest exceptions). Keep composer visible; publish cumulative partial text by replacement, not duplicate appends. Preserve the draft/selection policy explicitly; never overwrite unrelated manual edits or a different room's draft. Active mic action must remain Stop dictation even after text appears—not become Send or Stop agent. Empty/unsupported/denied states remain usable and truthful.
3. Second tap stops capture, accepts the final complete result when available, keeps the latest valid text if no final arrives, and never auto-sends. Establish bounded finalization from native callbacks, not a guessed sleep. Guard rapid taps, stop/cap races, cancel/dispose during startup/finalization, stale old-session callbacks and recognizer early end/errors. Keep the60s cap and release the microphone on navigation/background as appropriate. Do not keep claiming Listening after native capture ended.
4. Tests: cumulative partials/corrections, final after native stop returns, empty/silence, permission prompt followed by stop, rapid start-stop, cap/stop/cancel/dispose/generation/room races, no duplicate/no send, narrow320px/2x controls and existing composer queue/steering/attachments/hardware behavior. Honest platform limitations: application tests cannot prove acoustic transcription accuracy; if local-only enforcement or required engine capability is unavailable, report rather than weakening privacy.
5. From App cwd run targeted format/analyze/focused tests/full suite with only existing documented macOS-on-Linux sound-scale exclusion. Preserve plan75 baseline and code23 artifact. Build compatible offline ARM64 code24 with same package/signer; no stage/commit/push, sibling/global config changes, worker ADB or additional agents. Durable worker report is bound by orchestration output.
6. Parent independently reviews lifecycle/data-integrity correction, verifies exact-source artifact, then performs authorized in-place install. Observe real phone controls; human voice sample is a separate necessary acceptance gate, not replaceable by synthetic callbacks or automatic audio playback. Do not submit diagnostic speech to running agents.

## Draft milestone — 2026-10-11

Worker completed **BLOCKED DRAFT** and released sole App writer ownership.629 full-suite tests passed before final style-only edits, with only the documented Linux/macOS sound-scale exclusion. Exact-final scoped checks:52 voice tests,13 composer tests, format0 changes and analyzer0 issues. The629 pass is not claimed against the final hash. This is not an independently reviewed/native-built/device-accepted release. Private report: managed workflow artifact `201472ec-ab2e-44ce-9a3c-79c0e77ef3ff/app/76-tap-dictation.md`; source/diff manifests and gate logs are under `app/build/76-voice/`. Code23 remains installed and its artifacts are preserved.

Cached speech_to_text7.4.0 Android code can create a generic recognizer when onDevice=true but local capability is unavailable. A separate App capability probe cannot prevent the library's later fallback/race, so it does not enforce the existing local-only policy. This establishes a code path, not evidence that this phone uploaded audio. The tested Dart draft is retained, but no code24 was built/accepted. Native recognizer reuse also dispatches untagged callbacks to the current listener, beyond what Dart-generation fake tests certify; some unavailable/locales-support branches can leave native completion unresolved. These are additional native-boundary gates, not proven phone failures. Same-version local vendoring/patching, license/provenance retention and offline lock/path metadata changes have been proposed to the user and are pending explicit approval; no global cache patch, new provider/download or permanent voice-disable substitute is authorized.

## Renewed phone report

User reports the typing microphone records the first word and ignores subsequent words, and asks to continue unresolved issues. Parent confirms installed package remains **1.2.0/code23** using Android package metadata, without opening/reading another chat or accepting microphone permissions. The retained Dart draft is still NOT installed. Code23 baseline stops native capture then immediately returns the latest partial; it does not await the later real final result and shows no live cumulative composer. These are established source mechanisms, not a new acoustic reproduction or proof of the exact first-word cause.

A subsequent exact-current-checkout plan79 gate passed **633 full tests** (existing platform exclusion), including the byte-identical final voice draft, plus clean analyzer. This closes the earlier final-style host-suite gap for that mixed source snapshot, NOT native voice privacy/acoustic/build/device acceptance. The UI-only code24 candidate deliberately uses original HEAD/code23 voice, not this draft; its build number does not mean voice shipped.

Do not misrepresent the blocked draft as a delivered fix. Same-version App-local speech-library vendoring/native enforcement is still awaiting specific approval; the renewed report does not authorize downloads, generic/cloud fallback or automatic microphone acceptance. After approval, native callback-generation/early-end handling and a human multiword dictation/second-tap test remain release gates. Accordion work is source-only and must not accidentally publish this draft.

## Recovery and authorization — 2026-10-11

User approved local copying/patching and necessary continuation at 18:41 UTC, then explicitly requested recovery from Pi history in a new context. App-local vendoring of the cached speech_to_text 7.4.0 library, retaining license/provenance and minimal offline dependency-path metadata, is now approved. No global pub-cache source patch, downloads, cloud fallback, agent restart, automatic microphone permission acceptance or commit/push.

Exclusive App source owner: native worker `462bdc35-4a2b-4363-b889-c76a9844da9a`, mission `6fb323f8-c870-4add-af2c-2d8c4b80cba3`, durable output binding `app/76-native-dictation-fix.md`: native speech enforcement/callback lifecycle correction, coupled to the retained Dart dictation draft. This is one tightly coupled capture-lifecycle seam: splitting its native generation contract from the Dart listener would obscure the same race. Preserve accepted code23 renderer and plan79 accordion exactly. Code24 is the separate already-built UI-only artifact; the eventual voice artifact must be code25 or higher and separately reviewed before parent installation. Human multiword speech acceptance remains pending.

### Native validation decision

Worker reported offline `:speech_to_text:compileDebugKotlin` needs an uncached Flutter debug embedding; no download attempted. Parent approved offline `:speech_to_text:compileReleaseKotlin` using the existing release embedding/compiler (plugin classes only, no APK), plus a bounded JVM harness compiling/executing actual patched Kotlin against explicit Android/Flutter doubles if Robolectric/JUnit are not cached. Retain debug failure evidence, exact cached versions and test limitations. Release compilation and doubles-based lifecycle proof do not establish real Android recognition/acoustic correctness; independent review/build/device gates remain. Supervisor request `aea66eb5-ab8f-4398-a725-2de0ddaf5b29` answered; no further pending requests at this checkpoint. Both voice and display producer workers are still running, with no completed handoff yet.

### Completed native source handoff / review

Worker `462bdc35-4a2b-4363-b889-c76a9844da9a` released App source ownership; saved result is its bound `app/76-native-dictation-fix.md`. Final source gates: 55 focused / 636 full tests, clean analyzer/format, offline release plugin compilation and 199 assertions against actual patched Kotlin with explicit JVM framework/channel doubles. Parent independently matched Kotlin `3974625934371b18a67b8874883c7d9380393303057de89a3a6a2fc53ce2a9f6`, adapter `ed140bbeb916c7afd3f9bc66dd4a9a85141d0928f033a31eed926c0e2d48fa72`, service `4bf86357c7ab6aaa9d0ed60a2cc192bae2bb16ae715cd254c4461743c459e7eb`, ViewModel `849c285e431c5990f47353acd4f458e2e1af908e38d3626d1986657e1c64f52d` and preserved APK23/24 hashes. No voice APK built or installed.

Fresh independent reviewer `79255611-cfba-46cf-a20c-1c7fe2b75f4e`, mission `cac501f4-f25f-4acf-bbbe-abe2fc9f0732`, output binding `app/76-native-dictation-review.md`, now owns read-only review of retained Dart UI capture seam plus native vendor correction. App source frozen; App naming consumer waits until source review/corrections and exact-source voice build snapshot are settled. Read completed report on native wake, arbitrate findings, then assign separate code25+ build owner. Real recognizer/human speech acceptance remains pending.

### Source accepted / code25 build underway

Independent reviewer `79255611-cfba-46cf-a20c-1c7fe2b75f4e` completed: no qualifying issues, OK with notes for source only. Parent read the full review and independently matched all eight reviewed source hashes plus production/test manifest identities. Android Binder/Looper, local model/microphone and acoustic behavior remain unproven by JVM doubles.

Exclusive App BUILD/STAGING worker `57e9f930-6336-42a2-a532-85d39c90b085`, mission `9c2ee27b-8ed6-48ed-8365-4bee6221ca55`, output binding `app/76-code25-build.md`, now assembles/validates an isolated exact-source code25 candidate. Only private stage and build evidence writes; frozen App source is not concurrently changed. Parent owns package/signer acceptance and authorized in-place install. Naming consumer still waits for the frozen build snapshot/delivery milestone.

### Build-cache decision

Supervisor request `739f3755-0283-4296-9cbe-fa470495c255` approved read-only copying/reflinking immutable cached module artifacts/wrapper distributions from an active cache into the new private Gradle home, excluding daemon/locks/runtime/journals/build caches. Required bounded offline metadata snapshots must match before/after/copy hashes; incoherent or changing input is a blocker, not permission to fetch. No daemon shutdown or shared-cache writes authorized. Private tools may create their own locks/state. Exact cache selection/provenance remains a build-report gate.

### Code25 artifact blocked / packaging correction

Build worker completed/released and Parent read its report, independently verifying checksum/package/signature and immutable manifest identities. **Initial code25 artifact is rejected and was NOT installed.** APK SHA256 `4eb038c6c8cde723443be1f76ae0ebff648b36d3862e52541e0f9f92437e6328`; its sole `classes.dex` is byte-identical to stock UI-only code24: 1,236,496 bytes, SHA256 `666ffcdf04ed33f601592d5835de555aa4f7d67f8283dd51dba9843d0f820b8e`. Compiled patched Kotlin intermediate classes and NOTICES/license inclusion do not establish native patch inclusion in the delivered DEX. App AOT differs, but source provenance still requires verification.

Original build report retained as sibling `76-code25-build.pre-correction.md`. Validated recovery workflow `3b80e4b7-f2d4-41ea-be1d-cd8e9aa575ae`, mission `db7ded22-5832-4b65-b6e7-a6280b23792b`, revives the known same-model builder for private-stage/package diagnosis and correction only. Parent requires actual packaged plugin capture/listener/tag and on-device-only method evidence, not another intermediate-class claim. Preserve rejected artifact and all evidence; new candidate uses distinct `code25-corrected.apk`, same never-installed code25. No product-source changes, shared cache cleanup, downloads or device/install operations authorized in that lane. App naming consumer remains deferred while BUILD ownership is active. Phone remains code24.

### Corrected artifact independently accepted and installed

Correction writer `a030b832-39d3-4baa-8458-c434ce4e9335` released BUILD ownership. Root cause: missing ignored generated Android `GeneratedPluginRegistrant.java` in isolated snapshots let R8 strip all native plugins; intermediate Kotlin compilation/license proof was insufficient. Original code25 and all prior evidence preserved; no corrected-source logic change. Corrected APK `app/build/76-voice/code25/code25-corrected.apk`, SHA256 `e6277eb1700bc2c351d4cf6120978da90447da335dad503020fe5eeaa6874044`, DEX `9b69d08d617339e268890806096e3bac5866bc12b27714f45f3b11604b6de7b4`, same package/certificate, version25.

Parent independently recomputed all 421 reviewed file hashes, extracted the actual corrected APK DEX, reran cached dexdump, checked executable registrant/plugin/listener/capture-tag branches, two on-device factory invocations and zero generic factory invocations, plus AArch64 app/engine and package/signature/checksum. Private parent evidence `/tmp/parent-code25-gate-6ztq0t1s`; writer retains detailed kernel→AOT→merge→strip→APK provenance. This establishes static artifact inclusion, not acoustic/local-model/microphone behavior.

Phone temporarily disappeared from ADB, then returned; authorized `adb install -r` of ONLY corrected APK succeeded. Device R5CXB2PGC2H now reports 1.2.0/code25, activity launch succeeded. No data clearing, automatic microphone permission/audio or diagnostic Send. Human multiword tap-start/live-text/tap-stop/final-word acceptance and device microphone/data-retention checks remain pending. Uncorrected UI-only24 is historical, not plugin acceptance evidence. App SOURCE/BUILD ownership is free for the separately approved plan81 metadata consumer; its future changes are NOT in installed code25.

## Definition of Done

- [x] User approves replacing hold/no-live feedback with tap-toggle/live composer; existing failure seam identified.
- [x] Regression failures and corrected tap/live/final-stop source implementation (host/native-doubles proof; device acceptance separate).
- [x] Existing composer/recognizer lifecycle regressions, analyzer and compatible corrected voice-inclusive code25 build/package gate pass (device/human proof separate).
- [x] Independent source review accepted (no issues found / OK with notes; APK/device gates separate).
- [ ] In-place device controls and human spoken-word acceptance verified; any host-only limits recorded.

## Next plans

Plan77 separately audits session-to-PC identity, latest-message freshness and distinguishing names. Neither voice work nor naming may loosen paired sender/room routing or fabricate live child telemetry.
