# Remote Pi Readable

Personal Android build replacing the thin Courier fallback with bundled JetBrains Mono 2.304. Regular, Medium, SemiBold, Bold, Italic and BoldItalic faces are bundled, so this font works offline. The Inter wordmark and platform sans-serif body text are unchanged.

## Android installation

- Package: `io.github.asolopovas.remotepi.readable`
- Launcher label: **Remote Pi Readable**
- Installs alongside `work.jacobmoura.remotepi`; the official app and its private data are untouched.
- Pair the new copy independently: run `/remote-pi` in a desktop Pi session and scan its QR with the new app.
- Set **Settings → Display → Text size → Large** or **XL** as desired. Existing text-size preferences and defaults are unchanged.
- The installed APK is an ARM64 release-mode local development build, signed using this machine's Android debug keystore. It is not an official store release. Keep `~/.android/debug.keystore` to make future compatible updates; do not publish its private key.
- Do not install official APKs over this package: their application ID and signing key differ. Update from a rebuilt APK of this fork using the same signing key.

## Chat controls

- Markdown code blocks, tool commands and edit diffs scroll horizontally by default and keep their original line breaks. Each block has a visible horizontal scrollbar, **Wrap / Scroll** toggle and copy button.
- Tool name, **Wrap / Scroll**, copy and status share one compact top row; there is no extra "command" label or repeated footer status. Neutral borders, reduced padding and no glow keep attention on the content. Code windows have extra spacing above and below. Actual error details remain below the command when present.
- Recognized `subagent` launch calls are moved out of the main timeline. A single small **Subagents · N** button above the conversation opens their modal; workflows do not take up vertical space in the main chat. Tap a task header inside the modal to expand its assignment and available output. **Expand all / Collapse all** sets the modal default, persisted as **Settings → Display → Collapse subagents**.
- Main messages stay expanded, with newest output at the bottom. **Latest** returns to the bottom after scrolling back through history. Wrapped and horizontally scrolled code blocks keep their state while scrolling through the timeline.
- **Hide tool calls in chat** also hides the Subagents button and contents.
- The current protocol provides tool start and terminal result, not live child transcripts or asynchronous completion events. Detached launch calls are labelled **Launched**, not **Done**; their task describes the assignment, not live activity. Workflow calls use available task labels. Tool wrappers that do not expose a named subagent call cannot safely be classified.

## Build and validation

Run inside `app/` with Flutter 3.44.4, Android SDK and JDK 17 or 21:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64 --build-number 15 --no-pub
adb -s R5CXB2PGC2H install -r build/app/outputs/flutter-apk/app-release.apk
```

Installed artifact: `app/build/app/outputs/flutter-apk/app-release.apk` (1.2.0, version code 15). A copy is at `~/Downloads/RemotePi-Readable/RemotePi-Readable.apk` with `SHA256SUMS`. Updates use the same signing key and preserve the existing pairing and preferences.

`flutter analyze` passes with no issues. The approved status-test assertions now check the single header status and absence of duplicate footer labels. The chat/preferences suite passed 121 tests. The final Linux-compatible suite passed all 541 tests serially, excluding one pre-existing test which assumes a macOS host and expects the Darwin sound-level scale even on Linux:

```bash
flutter test --no-pub --concurrency 1 \
  --name '^(?!.*forPlatform picks the darwin scale on macOS test host).*$'
```

Independent source reviews checked scroll/keepalive and modal provider/lifecycle behavior; the modal now follows the same hide-tool-calls policy as its button. On the Samsung SM_S926B, verification covered readable font rendering, compact single-row controls/status, horizontal scrolling, wrapped command lines, spacing around code windows, and opening/expanding/closing the subagent modal while retaining the main conversation. Clipboard copy is covered by the existing widget test. Live asynchronous child progress remains limited by the protocol as described above.

## Licenses

Preserve the repository's root MIT license. The bundled JetBrains Mono fonts are licensed under the SIL Open Font License 1.1; the complete license is in `assets/fonts/jetbrains_mono/OFL.txt` and is also included in the APK's Flutter assets.

Font source: <https://github.com/JetBrains/JetBrainsMono/tree/v2.304>.

Fork: <https://github.com/asolopovas/remote_pi>. Font changes are maintained on branch `readable-android-fonts`.
