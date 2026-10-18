# Mobile client

Flutter client for Android and iOS. Maintainer and author of contributions: **Andrius Solopovas**.

## Build and run

Use Flutter with Dart compatible with `pubspec.yaml` (`^3.11.5`); release CI currently pins Flutter 3.44.4. Install the Android SDK/JDK 17 for Android, or Xcode/CocoaPods on macOS for iOS.

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter run
flutter build apk --release --target-platform android-arm64
# macOS with the iOS SDK:
flutter build ios --no-codesign
```

Android requires API 34+; iOS deployment files and the identity plugin target iOS 18+. Identity backup needs iCloud Keychain on iOS, or Google Play Services, Google Backup and a screen lock on Android. Android Block Store restores identity to a new device; it does not provide live cross-device sync.

The Android application ID is `io.github.asolopovas.remotepi.readable`, with label **Remote Pi Readable**, so it installs separately from the upstream application. The namespace remains unchanged for native compatibility. Supply release signing through ignored `android/key.properties`; without it, Gradle uses the local debug key even for release-mode builds. Preserve the signing key privately for compatible updates. No APK or signing key is included here.

## Connect and use

1. Build/install this client.
2. In a desktop Pi session using this checkout's extension, run `/remote-pi` and `/remote-pi pair`.
3. Scan the QR code. Set the app and extension to the same HTTP(S) relay URL.

Pair this copy independently; existing installations and their data are not migrated. TLS is not E2E encryption. See the [protocol](../PROTOCOL.md) and [secure launcher guide](../SECURE-LAUNCH.md).

The readable client bundles Fira Mono Nerd Font, supports collapsible/wrapped tool output and local dictation. On Android the vendored speech plugin requires an available on-device recognizer and fails closed rather than falling back to cloud recognition; review text before sending. Source and host tests do not establish microphone/model availability or physical-device acceptance.

## Maintain

`lib/` separates `domain`, `data`, `ui`, `config` and `routing`; dependencies flow through domain contracts. See the consolidated [development instructions](CLAUDE.md) before editing. Identity storage is documented in [packages/remote_pi_identity](packages/remote_pi_identity/README.md); speech changes are recorded in [vendor/speech_to_text/PATCHES.md](vendor/speech_to_text/PATCHES.md).

Licenses: [MIT](../LICENSE), Fira Mono [OFL](assets/fonts/fira_mono/LICENSE), and [vendored speech plugin](vendor/speech_to_text/LICENSE). The `highlight` dependency is MIT © 2019 Rongjian Zhang; Flutter collects dependency licenses. Keep required assets and native resources, but never commit `build/`, SDK paths, credentials or signing material.
