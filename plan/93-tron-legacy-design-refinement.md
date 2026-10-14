# 93 — Tron Legacy design refinement

## Context

The operator requested typography, layout, spacing, and color refinement using their actual VS Code Tron Legacy configuration, Impeccable, reusable tokens, accessible contrast/states, responsive layouts, and running-UI validation. Preserve Remote Pi identity and functionality; avoid excessive neon and arbitrary trend-driven redesign. The later instruction to proceed without further questions removes the need for another scope interview, not the need for evidence or existing project boundaries.

**Status: App status/dictation refinement implemented and source-reviewed; production-widget fixture matrix verified; code37 actual-main candidate built and release startup verified on the emulator with explicit ARM64 selection. Paired affected routes, real-phone/audio acceptance and complete diagnostic coverage remain open. Site and Cockpit refinements remain proposals, not implemented work.** At the operator's request, root instructions now permit scoped direct execution/native workers; missing Cockpit/cmux is no longer an execution prerequisite. Provisional scope is shared semantic consistency across App, Site, and Cockpit, prioritizing the existing mobile client's readability. Each surface keeps its native density and typography; this is refinement, not a rebrand.

## Reference and incumbent evidence

- Verified `~/.config/Code/User/settings.json`: active `workbench.colorTheme` is `Tron Legacy`.
- Inspected `~/.vscode/extensions/bcomnes.tron-legacy-1.2.0/themes/tron-legacy-color-theme.json`: base `#14191F`, input `#202831`, foreground `#AEC2E0`, blue `#267FB5`, amber `#FFB20D`, success-family green `#95CC5E`, error pink `#FF5370`.
- User overrides: sidebar/activity/tab backdrop `#14191F`, borders `#2B323A`, active tab `#3E5169`. Overrides take precedence over extension defaults.
- Impeccable context ran once at repository root; no PRODUCT.md or DESIGN.md found. Existing implementation remains design authority for this scoped refinement. Loaded `reference/critique.md`, `reference/polish.md`, and `reference/document.md`. Native Flutter surfaces have no HTML/CSS detector verdict.

### Source-level findings (not rendered verdicts)

| Surface/source | Observed | Refinement/verification required |
| --- | --- | --- |
| `app/lib/ui/core/themes/app_colors.dart` | Already uses Tron base `#14191F`, readable pale text, and semantic ThemeExtension tokens; accent remains `#8BE9FD` and status colors use a different palette. Light theme exists. | Preserve readable existing body text; reconcile accent/status roles with the verified reference without flattening contrast. Keep light mode. |
| `app/lib/ui/core/themes/app_theme.dart` | Existing Material mapping; focused inputs use a 1.2px accent border; hints are 13px mono; secondary/onSecondary pairing is assigned independently. | Check full Material role pairs, touch/focus visibility, readability and large text in actual widgets, not only custom components. Preserve earlier mobile font/readability work. |
| `site/src/app/globals.css` | Existing CSS variables, Space Grotesk/Hanken Grotesk/JetBrains Mono roles, pure-black/white palette, sky-blue aliases named `--green`, radial glow, body `overflow-x: hidden`. | Preserve type families and content; clarify semantic aliases, reduce redundant ambient effects, test clipping rather than hiding overflow. |
| Same Site stylesheet | `--faint: #6B6B6B` is 3.94:1 on black; `:focus-visible` not found in this stylesheet; responsive queries and reduced-motion handling already exist. | Audit actual faint-text usages; this token fails 4.5:1 for normal text. Check rendered keyboard focus before claiming a missing browser focus indicator. Preserve and verify existing responsive/reduced-motion behavior. |
| `cockpit/lib/app/core/ui/themes/app_colors.dart` | Separate gray/violet base, blue accent, multiple ink levels; supports light/dark and JSON theme import/export. | Add/refine Tron through existing theme infrastructure; preserve user themes, serialized keys, terminal ANSI semantics and status distinctions. Do not globally replace user's saved custom palette. |

## Expected structure

Implementation owners: **App**, **Site**, and **Cockpit**, each confined to its subproject. No Relay/Extension behavior changes for a visual task.

Reuse existing semantic token APIs rather than introduce parallel color systems. Workers document implemented, measured tokens in subproject DESIGN.md and follow Impeccable's document/sidecar contract where applicable. This plan is a proposal, not a fabricated record of implemented tokens. Preserve existing branding assets, names, navigation, readable fonts, controls, keyboard shortcuts, pairing, terminal rendering, and all supported light/custom themes.

### Proposed reusable dark tokens

Values derived for accessibility are explicitly distinguished from literal VS Code values.

| Role | Value | Origin/use |
| --- | --- | --- |
| background | `#14191F` | Exact configured backdrop |
| surface | `#1C232B` | Theme surface |
| surfaceRaised / input | `#202831` | Theme input |
| selectedSurface | `#3E5169` | User active-tab override |
| borderDecorative | `#2B323A` | User override; not sole control boundary |
| borderControl | `#748AA6` | Theme syntax primitive, usable for boundaries; not normal text on raised surface |
| text | `#AEC2E0` | Theme foreground; retain App's brighter text where required for incumbent readability |
| textStrong | `#D0DFE6` | Theme variable foreground |
| textSecondary | `#91A6C2` | Existing App token retained for readability |
| accentReference | `#267FB5` | Literal theme blue for non-text accents; not universal foreground/button fill |
| accentText / focus | `#8BBBDC` | Accessibility-derived pale blue; verify against each adjacent/selected surface |
| actionFill | `#206F9D` | Darkened reference blue for white button text |
| actionHover | `#1B628C` | Derived state |
| actionPressed | `#175577` | Derived state |
| onAction | `#FFFFFF` | Accessible on all three action fills |
| warning | `#FFB20D` | Literal theme amber |
| success | `#95CC5E` | Literal theme green |
| error | `#FF5370` | Literal theme error |

Calculated WCAG sRGB contrast, opaque pairs only: text/background **9.75:1**; text/raised **8.23:1**; secondary/raised **5.99:1**; accentText/raised **7.27:1**; white/action **5.49:1**, hover **6.62:1**, pressed **8.07:1**; warning/raised **8.25:1**; success/raised **7.86:1**; error/raised **4.77:1**. These do not prove rendered accessibility: alpha, gradients, selections, disabled states, and widget color mapping require separate measurement.

Important traps measured from the actual reference: white on literal `#267FB5` is **4.39:1**, reference blue on raised surface **3.40:1**, `#748AA6` on raised **4.21:1**, and user decorative border on base **1.36:1**. Do not mechanically copy them into normal text or essential control boundaries. Pale blue on selectedSurface is **3.96:1**, so selected text needs another verified role, not accentText blindly reused.

### Typography, geometry, and states

- Retain each surface's existing font families. Sans for prose/UI; mono for code, terminal content, and identifiers, not every label.
- Proposed shared spacing scale: **4, 8, 12, 16, 24, 32, 48, 64** logical pixels/CSS px; map existing contextual spacing without forcing identical native/web density.
- Website body 16–18px and 1.5–1.65 line height; constrain long prose to approximately 60–75 characters. Keep existing mobile font preferences and text scaling. Do not shrink readable App text to match desktop chrome.
- Explicit normal/hover/pressed/focus-visible/selected/disabled/loading/error states. Selection and status also use text/icon/shape, not color alone. Visible keyboard focus must survive selected surfaces and not be clipped.
- Distinguish container dividers from essential input/control outlines. Reuse existing component radii; rationalize accidental near-duplicates rather than introduce a decorative shape language.
- Prefer restrained solid surfaces and whitespace. No text glow, animated grids, flashing statuses, or added broad neon halos. Respect reduced motion, with no loss of status information.

## Steps and acceptance

1. **Capture baseline in each running surface.** Record route/state, viewport, theme, text scale, and screenshots before edits. Scope App to pairing/session list/chat/settings and representative composer/terminal/connection states; Site to home/download/legal navigation; Cockpit to workspaces/terminal/settings/dialogs. Acceptance: reproducible baseline, no synthetic screenshot presented as production.
2. **Map semantic tokens.** Update existing APIs and document accessibility derivations above; preserve user-theme serialization and light mode. Inspect all Material ColorScheme foreground/background pairs and terminal/code palettes independently. Acceptance: no scattered replacement hexes or changed behavior/data model; opaque and composited contrast checks pass for actual usages.
3. **Refine layout/type.** Fix only current source/rendered findings: hierarchy, line length, inconsistent gaps, wrapping, responsive overflow, focus clipping and status legibility. Do not replace branding or redesign navigation. Acceptance: typography uses existing families/preferences; no functionality removed.
4. **Interaction and accessibility.** Keyboard tab traversal, focus visibility, native semantics, disabled/loading feedback, errors, hover/press, reduced motion, screen-reader labels, and comfortably usable pointer/touch targets. Aim for 44–48px touch targets with appropriate platform density. Require normal text >=4.5:1, large text >=3:1, and essential component/state boundaries >=3:1. Acceptance: concrete per-state checks, not palette-only claims.
5. **Responsive running-UI verification.** Website at 360x800, 768x1024, and 1440x900; Flutter mobile at comparable 360/412 logical widths and tablet width; Cockpit at 1024x768 and 1440x900 with narrow split panes. Check 200% text/zoom, long session names, long paths/code, keyboard open, dialogs and error states. Intentional terminal/code scrolling is allowed; page-level accidental overflow is not. Acceptance: saved before/after screenshots, no clipped essential controls/text, preserved navigation and scrolling.
6. **Quality gates.** Run each owner's focused tests/analyzer in its own cwd, active LSP checks for changed supported source, and a single final Impeccable `detect --json <changed web targets>` pass on changed Site source. No native detector success claims for Flutter. Manually classify detector findings; browser evidence remains separate. Acceptance: test/diagnostic/detector results and remaining issues documented accurately.

## App status/dictation slice — 2026-10-14

- Production Chat and session tiles share a green rotating working glyph, visible status labels, unchanged status priority and a static reduced-motion alternative. Dark working uses literal Tron `#95CC5E`; light uses accessibility-derived `#426B21`. Actual surface/composite contrast is at least **8.17:1 dark / 5.50:1 light**. Implemented roles are documented in `app/DESIGN.md`.
- Status is separated from truncating metadata; Chat device/status wraps at large text. Parent inspected before/after narrow dark tiles, narrow dark Chat and large-text light tablet tiles. Sixty font-loaded PNGs cover production widgets with inert synthetic state at 360/412/768 logical widths, dark/light and 100%/200% text. These are **not installed-app, paired-device or acoustic evidence**.
- Supported `androidNoBluetooth` avoids explicitly starting/stopping headset voice mode or requesting Bluetooth permission during handset dictation. Haptics are explicitly disabled. Local recognizer segments now say “Restarting local dictation”, not relay reconnection. Continuous dictation, final-word retention, session/lifecycle fencing and on-device-only recognition remain intact.
- Android recognition-service beeps have no supported mute switch. No global volume mutation or hidden API was introduced; acoustic silence and actual handset/headset routing remain unverified.
- Worker validation: **157 Flutter tests**, **219 actual-plugin JVM assertions**, clean 13-file Dart analyzer/format gates. Parent independently verified all **17 source**, **60 screenshot** and **7 validation-log** hashes in `app/build/93-dictation-status/evidence-manifest.json`, reviewed production changes and inspected representative images.
- Active all-server pi-lens scan: **0 errors/warnings, 7 files confirmed clean, 10 inconclusive timeouts** across 17 changed files. Dart SDK local-bin links restore actual Dart language-server availability, but this does not turn an inconclusive diagnostic result into a clean claim. Existing native Flutter/Kotlin/Gradle tooling deprecation warnings remain disclosed.
- No physical phone is currently connected. No microphone recording, pairing migration, device-data clearing or APK publication occurred in this slice. Actual-main packaging and emulator runtime validation follow source acceptance; broader Site/Cockpit and full App accessibility claims remain open.

## Combined candidate and bounded runtime acceptance

App refinement commit `41e56899` and the reviewed phone-launch handoff are integrated at `60e608cc3343d08c6d50122d1b554c63dec03475`. The combined serial suite passed 810 tests and hit four perpetual-spinner fixture settle timeouts. A test-only reduced-motion correction preserves navigation/layout assertions; the affected file plus independent spinner tests then passed all seven checks. This is not a claim of one clean full-suite rerun. `lib test packages vendor` analysis is clean; whole-directory analysis additionally finds one historical build-helper filename info, preserved rather than suppressed.

- Candidate: `app/build/93-dictation-status/code37/code37.apk`, version 1.2.0/code37, actual `lib/main.dart`, ARM64 release-mode personal debug-key-signed fork. SHA256 `bd1dcd3e9d98e5c0cdbad124a2bbde38cdd9640f60ae5b3cb44ab2877a7eeadc`, 45,819,622 bytes. Package and existing signer unchanged; no APK upload or physical-phone installation.
- Parent verified all 466 final App source hashes and all 14 explicitly enumerated new compiler inputs against frozen pre/post source. Fresh packaged AOT matches independently stripped compiler output. Cache evidence is qualified: 2329 cached hashes match, 14 inputs absent from the warmed cache have frozen-source/fresh dependency evidence, zero mismatches. Original strict cache failure is retained, not relabeled passed. Actual native DEX is identical to the proven code36 baseline.
- Default emulator installation initially selected x86_64 because bundled native plugins advertise that ABI, so the ARM64 release engine could not load. A separate actual-main x64 debug candidate reached `/sync-required` and produced 12 responsive captures. Those are explicitly debug gate evidence, not release or paired Chat acceptance. The existing App preference clamps system text scaling to 1.0 at this gate; system-200% captures do not establish 200% App text.
- Parent then used supported `adb install --abi arm64-v8a -r` on **emulator-5558 only**. The unchanged release installed with `primaryCpuAbi=arm64-v8a`; its on-device hash matches the candidate. Stable PID16857 reached the genuine sync/security gate, with zero searched fatal/unsatisfied-link/render-overflow/unhandled-exception markers. Screenshot/XML and receipts are under `code37/runtime-arm64-override/`. This is ARM64 native-translation smoke, not physical ARM64 acceptance. Emulator now holds the **release** candidate, superseding the earlier debug install.
- Account, screen-lock and Backup requirements were not bypassed; pairing, microphone permission and other app data remain untouched. Chat/status/agent-launch end-to-end and human acoustic/headset checks remain unverified. The worker restored display/density/font/night-mode settings; the parent ABI check did not alter them.
- The combined active diagnostic attempt exceeded its wrapper budget; recovered findings identified missing Extension dependencies and lifecycle-helper style warnings. Locked dependencies were restored offline without scripts/downloads or lock changes; source refactors and a parent-discovered joined-cleanup Stop race were corrected with deterministic regression coverage (plan 94). Final targeted active all-server check of four Extension files and the corrected App fixture: **0 diagnostics, 3 confirmed clean, 2 inconclusive** (one timeout and one silent-on-clean server). Identified findings are resolved; complete language-server coverage is not claimed.

## Definition of Done

- [x] Located and inspected actual VS Code theme and user overrides.
- [x] Impeccable context/guidance loaded; incumbent source audit recorded.
- [x] Proposed semantic palette and contrast pitfalls calculated.
- [ ] Eligible workers implement scoped refinements.
- [ ] Reusable implemented tokens and role/state mappings documented.
- [ ] Running UI verified at representative sizes and text scaling.
- [ ] Functionality, accessibility, light/custom themes, and focused tests verified.
- [ ] Final improvements and remaining issues reported with actual evidence.

## Next plans

Execute concrete per-surface tasks through scoped native workers or directly in each subproject, using one writer at a time per checkout. Treat any missing runtime/dependency/device as an explicit validation blocker, not permission to claim completion. Relay deployment proceeds separately under plan 92.
