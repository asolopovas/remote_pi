# 96 — Color tool-output code and toggle all accordions from the header

## Context

User reports uncolored code and requests a header icon toggling all accordions. Explicit ADB inspection permission confirmed Python from a symbol-reading tool rendered as plain text on the physical Samsung. Existing output language inference handles only `read`, so symbol/enclosing/custom source readers miss syntax highlighting. Inspection captures remain private temporary files, not repository fixtures or transcript logs.

## Expected structure

Parent is the sole App writer; fresh read-only reviewer checks the UI lifecycle. Scope: chat header, page-local expansion command, tool/code/subagent disclosure owners and scroll anchors, output-language inference and existing-library grammars, focused tests. No native/voice/transport changes, new dependency, message sending, microphone capture or permission changes.

## Steps and acceptance

1. Infer source syntax from supported explicit language hints or basename extensions for every source-reading tool, including symbol/enclosing tools and Windows paths. Preserve exact source/whitespace/copy, bounded parsing and safe unknown-language fallback. Add common Go/Rust/SQL/Java/Kotlin/Swift grammars from the already locked highlighting library.
2. Add a stable accessible 48dp header icon with clear Expand/Collapse-all tooltip. A page-local revisioned command affects tools, nested code/raw disclosures and both main/subagent views. New/lazy rows inherit the latest command; manual choices remain usable between commands. Reset on peer/room changes without changing persisted preferences or composer state.
3. Bulk commands must not pin every expanded lazy row or compete through individual align/scroll-return bookmarks. Preserve manual per-card alignment, copy, wrap/scroll and double-tap behavior. Keep standalone subagent preference controls, but omit duplicate panel-wide controls when the shared header exists.
4. Test actual syntax colors and lossless text, real ChatPage header at320px/2x, nested/global expansion, new streamed/lazy rows, manual overrides/wrap retention, peer scope reset and normal scroll behavior. Run scoped analysis, formatting and affected chat tests. Resolve fresh reviewer findings.
5. Continue the approved commit/push/in-place Android delivery lane with a higher-version real-main APK and source/AOT/package/signature/installed-identity gates. Reuse verified native DEX proof only if both native source and packaged DEX match build39. Preserve device data and active host conversations.

## Definition of Done

- [x] Real-phone plain symbol output inspected; syntax inference and common language coverage implemented.
- [x] Header toggle covers tools/code/nested/subagent disclosures with lazy/local-state safeguards.
- [x] Final affected tests/analysis and independent review pass.
- [x] Verified higher-version update committed, pushed and installed in place.
- [x] Actual device shows colored code and functioning header action (see exact inspection limits below).

## Validation and limits

All220 chat Flutter tests passed, including real ChatPage320px/2x, lazy-row disposal/manual choices, global nested/new-row expansion and exact colored symbol output. Scoped Dart analysis reports no issues; formatting and diff checks pass. Final active LSP confirmed seven paths clean with four timeouts; no all-path LSP claim. Fresh read-only reviewer72879d76 found no issues and returned OK. No acoustic behavior claimed; verified delivery is recorded below.

## Delivery and device inspection — build40

Source commit `cb86d251657746068584d459b108c32780f541c1` pushed to `origin/readable-android-fonts`. New archive: `app/build/releases/code40/`. Fresh ARM64 real-main kernel/AOT, full source/compiler closure/cache hashes, package/activity/version and unchanged signer gates passed. Native source and packaged DEX are byte-identical to verified build39, so its segmented/local-only native proof is reused rather than relabeled as a new native test run.

APK SHA256: `0f049fefed406c7e6e75e5bae621c0cc06442490ee3aec9326f270cd86017d0f`. Samsung `R5CXB2PGC2H` updated39→40 using targeted `install -r --user 0`: Success. Pulled installed base APK is byte-identical; app ID10054 and original first-install time remain unchanged. App launched and stayed alive during the12-second crash-only smoke with zero crash entries. Setup0.4s, build76.8s, artifact gate2.3s; these are build-lane stages, not a complete coordination benchmark.

Authorized read-only UI inspection confirmed the new header icon, bulk expansion including nested Details, subsequent bulk collapse, and visible syntax-colored JavaScript source on the phone. The original plain Python symbol result was inspected before updating; its precise output-language/color regression is covered by host tests, not falsely claimed as the same old block re-inspected on the handset after history moved. Temporary screenshots remain outside the repository. Returned the client to the user's preceding `andrius` conversation. No messages, host process-stop/launch commands, microphone capture, permission changes, uninstall or data clearing were performed.

## Next plans

Keep human dictation acceptance separate; this UI-only update preserves plan95's speech implementation.
