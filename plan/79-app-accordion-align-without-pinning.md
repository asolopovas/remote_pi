# 79 — Accordion expansion alignment without sticky headings

## Context

User explicitly changes the earlier plan72/75 accordion behavior: expansion should scroll the original accordion heading to the top of the chat content viewport, expand underneath it, and let that heading scroll away normally. It must not become a sticky duplicate/overlay. This is an explicit override of accordion-heading pinning, not removal of the fixed chat toolbar/session tabs.

Installed code23 and accepted plan75 rendering must survive. Plan76 speech changes remain an uninstalled, blocked draft; this UI request does not authorize native speech vendoring, dependencies or shipping that draft.

## Expected structure

App-only, single UI writer. Primary seam: `app/lib/ui/chat/widgets/accordion_viewport.dart`, production accordion/rendering tests and narrow documentation. Preserve the existing viewport-local expansion alignment and bounded edge-space handling where necessary. Remove accordion overlay pinning, original-heading hiding and heading-slot clipping. Original title/copy/wrap controls remain in their normal card position with one accessible interactive heading. No transport/history/naming/voice/config changes.

## Steps and acceptance

1. Add regressions for opening long and short edge tool/code/agent accordions in the production normal/reverse chat viewports. Once expanded, the original heading aligns below fixed session/tabs, with body underneath and no pinned-heading overlay.
2. Scroll further: heading leaves the viewport naturally; body uses the full chat viewport without a sticky-heading blank/clipped strip. Scrolling back reveals the original heading and working collapse/copy/wrap controls. Nested code/embedded previews behave identically, without replacing the outer heading with another sticky header.
3. Retain one alignment per explicit collapsed-to-expanded transition, not repeated streaming/update auto-scroll. Preserve independent disclosure/Wrap/Scroll state, lazy-list/update/tab behavior, clipboard bytes and code23 decoded-output fallback/metadata. Cover collapse, room/tab changes, 320px width and 2x text, and bounded short-edge extent cleanup. No fixed delays/device pixel guesses.
4. Run focused regression tests, formatter and analyzer using existing cached Flutter tooling only; no downloads/pub get. Report exact source hashes and tests. Update old assertions/docs that deliberately required pinning rather than preserving obsolete behavior. No source edits outside the owned UI seam.
5. Parent reviews and coordinates a UI-only release/device check from a clean snapshot of accepted code23 plus this change, excluding blocked plan76 voice source. Do not stash/reset/discard drafts, build an APK from the mixed dirty App checkout, install, clear data, restart agents, stage, commit or push. Pairing/cache/settings/model choices remain untouched. Parent performs actual phone expansion/further scrolling/copy checks before acceptance.

## Implementation ownership

Native workflow `04ceee7a-c1a2-4a59-a331-304fa10bd87b` assigns the sole App writer to this seam, Sol medium, deadline1h. Parent retains plan/integration/ADB ownership; no concurrent Parent App source/build mutation. Source regression/format/analyze/full-suite gates are requested with cached tools and no APK. Presence-only installed activation happened before launch, without restarting/reloading roots. App voice remains unmodified/blocked; the related parallel Extension scout is read-only admission-contract preparation, not another App writer.

## Completed source/review milestone

Source writer `26076237-1cf6-4208-8328-46454382b22a` completed and explicitly released App source. Old implementation failed three production/four dedicated regressions; final 64 focused/633 mixed-checkout full tests, analyzer and formatter pass, with the existing platform exclusion only. Byte-preservation verification confirms accepted renderer and blocked voice files unchanged. Parent independently rechecked final hashes. Reviewer `7ac33069-cc22-4178-a728-7909d36dfa0d` returned **No issues found / OK with notes**, source seam only. Runtime phone remains code23 until parent delivery; source success is not a fixed phone.

Workflow `0459fd51-e52c-46ea-8eb0-b22171e8f3d2` runs a separate clean UI-only stage/build owner. Its stage overlays exactly code23 renderer production plus the accordion viewport onto HEAD; all voice production/tests remain HEAD. Missing external tracked protocol fixtures caused the initial isolated full-suite failures; parent approved HEAD-only fixture support extraction, not product mutation. Parent also approved only proven normal generated Flutter/Gradle/JNI .cxx cache writes, never source/config/dependency changes or downloads. Detailed final build provenance and package acceptance remain report-gated. Parent LSP probe found zero reported diagnostics but **all three checks timed out/inconclusive**; only CLI analyzer is confirmed clean.

## Recovered delivery — 2026-10-11

New coordinator read completed source reviewer and clean build artifacts; no completed work was rerun. Verified immutable APK SHA256 `8713f06434b240814c598bc76751d255a68827986c846488619d809e57a66d31`, certificate SHA256 `44dc580c702f2757fb296c989608dad2826e12e771cc7e4364d50bd587c8516a`, accepted code23 preservation and exact accordion source hash. Device R5CXB2PGC2H was still code23. Authorized in-place `adb install -r` succeeded; package metadata now reports 1.2.0/code24 and activity launch succeeded. No app data clear, agent restart or blocked voice publication. Actual accordion gesture/clipboard and retained-data acceptance are not inferred from install success and remain pending.

## Definition of Done

- [x] User requests non-sticky accordion behavior; fixed navigation and one-time alignment remain explicit.
- [x] Production regressions reproduce old pinning and pass with normal-flow headings.
- [x] Source review and exact-version mixed-checkout host gates pass; accepted renderer and blocked speech draft preserved (clean release-stage gates separate).
- [x] Compatible UI-only APK reviewed and installed in place (`adb install -r`), without clearing data; post-update pairing/cache UI acceptance remains separate.
- [ ] Actual phone shows one-time heading alignment, expansion below and natural header scroll-out, with functioning copy/wrap/collapse.

## Next plans

Continue plan75 remaining lossless-rendering device acceptance. Plan76 native speech approval and plan77 history/isolation remain separate. Parent retains plan78 installed-package ownership/activation gate; avoid launching another automatically exposed background worker before that count guard is safely activated.
