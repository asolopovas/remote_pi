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

## Build and validation

Run inside `app/` with Flutter 3.44.4, Android SDK and JDK 17 or 21:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64 --no-pub
adb -s R5CXB2PGC2H install -r build/app/outputs/flutter-apk/app-release.apk
```

Installed artifact: `app/build/app/outputs/flutter-apk/app-release.apk`.

Static analysis passed. The existing test suite passed 541 tests and failed one: `test/data/voice/speech_service_test.dart` assumes a macOS test host and expects the Darwin sound-level scale, so its platform assertion fails on Linux. No tests were changed. Android build and ADB installation succeeded; the home screen visibly renders JetBrains Mono. Paired chat verification requires pairing the new copy.

## Licenses

Preserve the repository's root MIT license. The bundled JetBrains Mono fonts are licensed under the SIL Open Font License 1.1; the complete license is in `assets/fonts/jetbrains_mono/OFL.txt` and is also included in the APK's Flutter assets.

Font source: <https://github.com/JetBrains/JetBrainsMono/tree/v2.304>.

Fork: <https://github.com/asolopovas/remote_pi>. Font changes are maintained on branch `readable-android-fonts`.
