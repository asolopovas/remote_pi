# Remote Pi Readable

Personal Android build with terminal-inspired blue-gray dark surfaces, pale foregrounds, cyan/teal accents and bundled **FiraMono Nerd Font** from the local terminal setup. Regular, Medium and Bold faces work offline; italic is deliberately synthesized by Flutter (no bundled italic face). Inter branding and platform sans-serif body text are unchanged. Light theme and existing theme/text-size choices remain available.

## Android installation

- Package: `io.github.asolopovas.remotepi.readable`
- Launcher label: **Remote Pi Readable**
- Installs alongside `work.jacobmoura.remotepi`; the official app and its private data are untouched.
- Pair the new copy independently: run `/remote-pi` in a desktop Pi session and scan its QR with the new app.
- Set **Settings → Display → Text size → Large** or **XL** as desired. Existing text-size preferences and defaults are unchanged.
- The installed APK is an ARM64 release-mode local development build, signed using this machine's Android debug keystore. It is not an official store release. Keep `~/.android/debug.keystore` to make future compatible updates; do not publish its private key.
- Do not install official APKs over this package: their application ID and signing key differ. Update from a rebuilt APK of this fork using the same signing key.

## Session identity

- Sessions lead with the actual working-directory basename (Unix or Windows), followed by the available path and session/room context. Duplicate project names remain separate rows with session names and room discriminators; full original paths remain available in session details.
- **Working**, **Online · idle**, **Reconnecting**, and **Offline** describe existing observed connection/working facts, not inferred agent roles or last activity. Models are secondary context, not project identity.
- Chat headings use the same project basename. **No messages available** means the visible history is empty; being online does not guarantee content. A short reverse chat naturally bottom-aligns; blank space alone is not a paint failure.

## Chat controls

- Commands, edit diffs, and fenced assistant code start collapsed. Assistant prose remains visible. Tap the whole title/status header to disclose details; the header reports expanded state to accessibility services. Tool statuses use both colored icons and text; code examples show language and exact line count, not execution status.
- Expanded command/code/result/error text wraps to phone width by default. **Scroll** opts into horizontal scrolling; **Wrap** returns to wrapping. Copy/wrap controls sit separately below the expanded title so narrow screens and large text retain usable titles/statuses. These controls do not toggle disclosure.
- Known Bash/PowerShell commands (including namespaced tool names) render the actual command string even when timeout/other metadata is present. Codemode shows its code string; write shows its content with a language inferred from the file extension. Review separates **Command / Script / Source**, **Output**, and **Error**. Newlines, indentation, quoting and intentional literal `\n` remain unchanged: no formatter, interpreter or escape replacement is used. **Copy command** copies only the exact original command. **Copy source** does the same for scripts/write content. Optional **Details** exposes original arguments plus complete result/error, with **Copy full details**. Unknown/malformed shapes retain the raw safe fallback; actual JSON output remains Output. Styled edit hunks and raw payload remain available.
- Disclosed source and assistant/subagent code fences share theme-aware selectable syntax colors. Known shell, PowerShell, JS/TS, Python, Dart, JSON, CSS, XML/HTML and YAML aliases are supported. Unknown languages, parser failures, or source over 24,000 UTF-16 code units remain exact plain monospace. Highlighting is lazy (collapsed source is not parsed), with one bounded cached parse tree per mounted source widget, not an unbounded global cache.
- Every session shows **Main / Sub-agents**, with Main initially selected and an explicit empty agent tab. Sub-agents replaces the modal; its composer is hidden, so messages cannot accidentally appear directed at a child. Tab, scroll, disclosure and wrap choices survive ordinary updates/tab changes within the mounted peer/room; changing peer/room starts fresh.
- Single-agent launch cards disclose actual assignments and available output. Workflows/parallel calls remain one launch accordion listing known assignments plus **Shared workflow output**, not invented per-child cards or duplicated results. Known Markdown/code fences use the same individually collapsible code renderer. **Expand all / Collapse all** still changes the persisted **Collapse subagents** preference.
- Opening a tool, code or agent accordion aligns its heading below the fixed session/tabs. One viewport-local heading remains interactive while reading that expanded range; nested code takes over from its agent, and collapse/scroll-out/tab/room changes remove or hand off the heading. Copy/wrap work in the pinned heading; its original is noninteractive and excluded from semantics. The content is clipped below the heading slot rather than covered by stacked overlays. Alignment happens once per expansion, without animations/fixed waits or streaming auto-scroll. Short edge disclosures receive bounded viewport-derived extra scroll room only while needed by that expanded disclosure; collapse reconciles the extent.
- Main messages stay visible, with newest output at the bottom. **Latest** returns to the bottom. Explicit expansion/collapse and Wrap/Scroll choices survive lazy-list scrolling and ordinary updates; untouched default collapsed rows are not pinned in memory. State is scoped by peer/room and message identity, not a global cache.
- **Hide tool calls in chat** hides tool/agent contents, not the two session tabs; Sub-agents then shows its empty state.
- The connection supplies flattened launch-call text, not structured live child transcripts, nested tool events or asynchronous completion. Completed calls say **Call returned**, not child completion; existing explicit detached receipts remain **Launched**. Assignments are not live progress; action/control calls remain normal tool cards. No output files are fetched and no hierarchy/commands are inferred from prose. True per-child nested telemetry is an open transport/package gate, confirmed by `../.orchestration/results/72-subagent-data.md`.

## Build and validation

Run inside `app/` with the installed Flutter/Android SDK/JDK:

```bash
export PATH=/home/andrius/.local/share/flutter-sdk/flutter/bin:$PATH
export ANDROID_HOME=/home/andrius/Android/Sdk JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter analyze --no-pub
flutter test --no-pub test/ui/chat/{source_code,chat_page_rendering,chat_viewmodel,chat_page_appbar,agent_markdown,tool_request_card,subagent_panel,code_viewport,streaming_bubble}_test.dart test/ui/home/{session_tile,home_items,home_filter_tabs}_test.dart test/ui/core/themes/app_theme_test.dart test/data/preferences test/ui/settings
flutter test --no-pub --concurrency 1 \
  --name '^(?!.*forPlatform picks the darwin scale on macOS test host).*$'
flutter build apk --release --target-platform android-arm64 --build-number 20 --no-pub
```

Plan72 Code18 actual-device replay established long-command heading alignment/pinning/collapse, empty Sub-agents state and expanded workflow fallback; logs had zero searched rendering exceptions. The two visual follow-ups below were then observed and implemented for Code19. Host validation after the visual follow-up: **574 full-suite tests passed** (existing Linux/macOS sound-scale exclusion only), analyze clean; 2 header layout tests plus real ChatPage sticky/tab regressions pass. Source LSP coverage is unavailable; CLI analyzer success is not a complete LSP claim.

Plan73 host validation: **578 full-suite tests passed**, excluding only the existing documented Linux/macOS sound-scale test; **36 focused chat tests passed**, including exact multiline command + timeout copy, literal slash sequences, script/write source, details/output/error, token-color/lossless-span checks, unknown/huge fallback and production ChatPage 320px/2x pinned-copy/lifecycle coverage. `flutter analyze --no-pub` reports zero issues.

Local candidate: `build/app/outputs/flutter-apk/app-release.apk` (**1.2.0, code 20**), SHA-256 **c2f6b23ae158442a35fad242cd3d9cda7063fa889c1aef007e8e2c4f87311eb2**. Package `io.github.asolopovas.remotepi.readable`; signer certificate SHA-256 **44dc580c702f2757fb296c989608dad2826e12e771cc7e4364d50bd587c8516a** (unchanged); signature verified (v2). Built with `flutter build apk --release --target-platform android-arm64 --build-number 20 --no-pub`. Flutter app/engine libraries are ARM64 only; bundled third-party plugin libraries also advertise armeabi-v7a/x86_64 in APK badging. Existing Kotlin/Gradle migration warning remains.

Plan73 records Code19 already installed and device-checked by the parent for tabs/headings/pinning. **Code20 has not been installed or device-replayed.** Parent should install in place with the same package/key, replay an existing multiline Bash command containing timeout metadata (no command submissions/execution), inspect actual newlines/indentation and colored tokens/language in Light/Dark and 2x text, check exact Copy command versus optional Details/full copy, Output/Error, pinned copy/wrap/collapse, assistant/subagent code and room/tab lifecycle. Capture screenshots/logs and confirm no rendering exceptions. Worker did not install or use ADB/device.

## Licenses

Preserve the repository's root MIT license. Plan73 adds pure-Dart `highlight` **0.7.0**, MIT © 2019 Rongjian Zhang; official package README documents `Highlight.registerLanguage` and `parse(source, language: ...)` with `Result.nodes`. License/API were checked from the official pub.dev archive (`https://pub.dev/api/archives/highlight-0.7.0.tar.gz`, project `https://github.com/pd4d10/highlight`). The package license is included by Flutter's dependency license collection. Only this dependency was added; existing locked dependency versions were not upgraded. The active bundled Fira Mono Nerd Font faces are licensed under the SIL Open Font License 1.1; the complete license is in `assets/fonts/fira_mono/LICENSE` and is included in the APK's Flutter assets. Existing JetBrains Mono files/license remain preserved but are no longer the active font mapping.

Font source: local `/home/andrius/.local/share/fonts/FiraMono/` (no download).

Fork: <https://github.com/asolopovas/remote_pi>. Font changes are maintained on branch `readable-android-fonts`.
