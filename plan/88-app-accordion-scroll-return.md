# 88 — Restore viewport on accordion collapse

## Context

User requests retaining the existing snap-to-header on expansion, but returning to the same screen scroll position as immediately before that accordion was expanded when it collapses, including after reading/scrolling its expanded contents. This extends plans79/83/86; no sticky header or repeated streaming alignment.

## Expected structure

One App source/test owner. Inspect the shared `app/lib/ui/chat/widgets/accordion_viewport.dart` lifecycle and production tool/code/subagent disclosure integrations. Root owns this plan; implementation and tests run in `app/` only.

## Steps and acceptance

1. Capture the viewport return location before each explicit collapsed→expanded transition changes layout or aligns the header. Prefer a stable visible content anchor plus viewport-relative displacement where dynamic/reverse content makes raw offsets insufficient. Keep bookmarks local to the owning disclosure and peer/room/thread/scrollable.
2. On explicit collapse (header or supported body double tap), restore that bookmark after collapsed layout and temporary alignment extent cleanup. Returning must work even if the user scrolled within the expanded content. Clamp only when the original location no longer exists; never jump another room/thread or restore stale disposed views.
3. Preserve one-time expansion alignment and its 8dp gutter, natural header scroll-out, independent nested/multiple disclosures, copy/Wrap/text selection, and existing streaming behavior. Nested collapse returns to its own pre-expansion location; it must not consume the parent's bookmark. Opening again takes a fresh bookmark. Automatic removal/disposal is not an explicit collapse.
4. Add focused production-widget regressions: normal/reverse lists, long/short-edge cards, scroll-after-open then collapse, supported double-tap collapse, nested return, repeated cycles, room/thread switches, and content updates. Assert the original visible content position, not just a stored number. Run changed-path format/analyze and relevant tests from App; report exact commands and limitations.

## Definition of Done

- [x] App implementation dispatched to dedicated native App worker `245d0a6a-0600-40a7-9cc6-ffe21d280f25`; sole SOURCE/TEST owner. User explicitly authorizes autonomous startup rather than requiring manual pane startup.
- [x] Expansion retains existing top alignment; collapse restores the pre-expansion reading position in focused production-widget checks. Source writer released ownership; no APK/device acceptance yet.
- [x] Nested/repeated/viewport-replacement lifecycle and focused regression checks pass: 16 focused tests, all nine new regressions fail on baseline. Changed-path analyzer and format clean. Full analyzer reports an existing generated build-file naming info only. Parent matched all four reported source hashes and inspected final test log/diff. Active LSP confirms one path clean; two timed out/inconclusive.
- [x] Root reviewed actual diff, final test log and exact source hashes. Independent reviewer `837ff547-bd2d-4f3d-936c-66c2f26d5f41` inspected production caller/session scoping and all new regressions: no findings, ready for source acceptance. Parent rechecked all four hashes and diff whitespace after review; unchanged. Build/install remains a separate delivery gate, not inferred from source acceptance.

## Authorized device delivery

User explicitly requests installation on their ADB device after commit/push. Dedicated worker `3a74e826-116f-459a-9dc2-9214dc2c30e8` owns BUILD/ARTIFACT/DEVICE only, from accepted committed HEAD `9c06e736711a0c53ddcd5adf8917dc029e914ab1`. Physical Samsung `R5CXB2PGC2H` is currently code33; emulator is excluded. Reuse the warmed offline build lane for a real-main ARM64 release with strictly higher versionCode and unchanged package/activity/signer, preserving source and app data.

- [x] Fresh accepted-source code34 APK built in 90 seconds and installed in-place on Samsung `R5CXB2PGC2H` with targeted `adb install -r` (Success). Same package/activity/signer; APK SHA256 `a56feeb6a2acb549ba903b84e4f46acbdc83006f06933423b586009ba010d90f`. Worker verified 450 tracked App inputs, 2,337 compiler hashes and fresh packaged AOT, then released BUILD/ARTIFACT/DEVICE. Parent independently matched APK/source digest and certificate, installed 1.2.0/code34/ARM64 and live process. Bounded launch/current-process crash smoke passed; this is not accordion UX device acceptance. No data clear, uninstall, private transcript/pairing inspection or remote prompts; emulator untouched. Tracked App source/config unchanged.

## Next plans

No unrelated UI, transport, settings or dependency work. Existing packaging/in-place update contract applies if delivery is authorized. Cockpit/cmux CLI and an App mesh peer are unavailable; user authorized autonomous startup, so the coordinator launched a native App worker in `app/`. No parent App code edits or root build/test commands.
