# 90 — Settings default for text wrapping

## Context

The user requests a Settings option controlling whether text wraps by default. Existing CodeViewport defaults to wrapping and provides per-block Wrap/Scroll controls. Preferences already persists display choices and Settings exposes a Display section.

The preference applies to existing wrappable code/tool/output blocks, not ordinary prose or Settings labels. Preserve wrap-on behavior until the user chooses otherwise and retain local overrides.

## Expected structure

One App writer owns Preferences → Settings Display → CodeViewport and focused tests: `lib/data/preferences/preferences.dart`, `lib/ui/settings/settings_page.dart`, `lib/ui/chat/widgets/code_viewport.dart`. Use existing provider/secure-storage infrastructure, no new dependencies. Preserve plan89's dictation implementation.

## Steps and acceptance

1. Persist `wrapTextByDefault`, default true unless storage contains exactly false. Hydrate before first frame, preserve unrelated keys and notify on actual changes.
2. Add an accessible `Wrap text by default` switch in Settings → Display with brief code/tool-output/local-override help. Saved on/off values survive reopening/relaunch. Maintain narrow-screen/large-text layout.
3. New blocks use the saved default; mounted blocks without explicit wrap choices follow preference changes. Explicit local Wrap/Scroll choices persist for stable widget identity. Disclosure/copy are not wrap overrides. Preserve expansion, copying, horizontal-scroll safety, keepalive, nested finite-width handling and plan88 accordion scroll-return behavior.
4. Test absent/true/false/malformed values, storage roundtrip and notifications; Settings accessibility/persistence; both block defaults, live updates and local overrides; disclosure independence, lazy-list state, nested 320px/2x layouts and exact copying. Run scoped format/analyze and affected Preferences/Settings/code/tool/accordion tests from App.
5. Parent source review before serial real-main ARM64 packaging/in-place installation. Verify current source/compiler/artifact identity, unchanged package/activity/signer and increasing version. Preserve app data/pairings; no uninstall, data clear, permissions/audio or unrelated changes.

## Validation and delivery

82 affected host tests passed; scoped analysis and formatting clean. Parent independently matched all six changed-file hashes and all 12 preserved dictation-file hashes. Active LSP confirmed two paths clean and four inconclusive; no all-path LSP claim.

Build36 delivered the accepted wrap default and dictation fix together. Source/compiler/packaged-AOT/signature/installed-artifact identity and bounded launch/crash smoke passed. Host tests and launch checks are not human visual/acoustic acceptance.

## Definition of Done

- [x] Persisted preference and accessible Settings switch work in both states (source/host proof).
- [x] Blocks honor the default while preserving local overrides and disclosure/copy/scroll behavior.
- [x] Scoped tests/analysis and parent source review pass.
- [x] Accepted higher-version Android update installed in-place.
- [ ] Human verifies saved-wrap visual behavior.

## Next plans

Verify dictation and wrapping independently. Plan91 reduces repeated delivery work without reducing install safety.
