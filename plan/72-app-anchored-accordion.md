# 72 — Session tabs, nested output and visible accordion headings

## Contexto

User explicitly requested: “when accordion opens I should see its heading at the top of the screen always.” Parent confirmed behavior: on expansion bring heading to the top below the chat bar, and keep it visible while reading that accordion's contents. Device code17 proved the issue: reverse chat scroll anchors bottom, so expanding long results moves the heading offscreen (`/tmp/71-try-now-expanded.png`, `/tmp/71-tool-expanded.png`). Collapsed defaults/wrap, Fira Mono, project labels and code17 list-identity fix must remain.

## Session tabs — explicit subsequent user requirement

Each session must have a persistent header with two tabs: **Main** and **Sub-agents**. Main shows ordinary conversation/tool accordions. Sub-agents replaces the old bottom-sheet launcher with an inline session tab containing an accordion per agent and nested output using the same tool/code/agent presentation recursively (matryoshka style). Tab counts and truthful status indicators are welcome; Main remains default and tab/scroll/expansion state stays scoped to peer/room. Always show both tabs, with an explicit empty Sub-agents state rather than a missing tab. Keep the composer targeting the parent session, not accidentally sending to a selected child; hide it on Sub-agents or label its target unambiguously. The explicit user request supersedes plan70/71's old preference for the dedicated modal; do not retain competing navigation.

**Data evidence:** `pi-extension/src/index.ts:2205` broadcasts `_stringifyToolResult(event.result)`; `_stringifyToolResult` unwraps only text `content`, discarding `details`. History similarly maps only content. Current App `SubagentInvocation.output` is mostly text. Rendering code fences with shared accordions is possible now; genuinely structured nested tool/child trees require a verified data contract. Do not parse arbitrary prose into guessed agents, statuses, or commands, and do not claim flattened text is full live child telemetry. A read-only Extension scout must establish existing package public events/artifacts and a safe additive transport design before any cross-project write. App phase preserves all output and renders known Markdown/code faithfully; report true nested-telemetry delivery as a separate gate until connected. No unapproved filesystem-path fetches from untrusted tool text.

### Supervisor decisions during implementation

- Approved one viewport-scoped registry and single pinned-header slot instead of custom paint/hit-test render transforms. Scope per peer/room/tab, coalesce layout measurements, exclude duplicate semantics/hit targets, deepest visible expanded content wins, and remove/handoff on collapse/scroll-away. Any viewport-derived alignment extent is bounded and temporary; no permanent empty regions or streaming-driven scroll fights.
- Scout report `.orchestration/results/72-subagent-data.md` confirms that installed pi-subagents has bounded async inspection but no documented universal observer/replay surface for arbitrary foreground child tool streams. Structured cross-project telemetry remains a separate capability-gated task, not claimed delivered by this UI phase.
- A multi-agent launch with only one flattened result stays one clearly labeled workflow accordion: list known assignments compactly and render **Shared workflow output** once. Explain on expansion that this connection does not supply per-agent output. Do not manufacture task-only empty child panels, duplicate the result across agents, or inherit launch completion as child completion. Single-agent launches remain individual accordions. This is explicitly partial fulfillment of true recursive child telemetry.

## Estrutura esperada

One App worker owns this single coupled disclosure/scroll-presentation seam: session tabs, shared header, command/code/subagent widgets, chat/tab viewport integration and focused tests. Root parent remains planning + ADB only. No dependencies, protocol/execution changes, commits/staging/push, Cockpit/cmux. Preserve all plan70/71 uncommitted changes and existing unique row identities. Parent owns device actions; worker builds only.

## Passos com critério de aceite

1. Reproduce the long-result expansion against actual reverse ChatPage list. After expansion/layout, position the real expanded header at the top of its content viewport (below fixed app bar/subagent launcher), not the bottom of the result. Handle offscreen/kept-alive rows, nested fenced-code cards and keyboard/insets. Do not use guessed pixel offsets or fixed sleeps; no auto-scroll on every streaming update after the user has moved away.
2. Keep the relevant heading available at the viewport top while reading its expanded content (sticky within that accordion's visible range). Collapse from that heading must work; status updates stay truthful. Preserve full content, selection, copy/wrap controls and individual expansion. When scrolling outside that accordion, its pinned heading must go away or hand off, not obscure another message. Multiple expanded cards must not stack overlays or duplicate accessibility announcements. Do not replace inline accordions with unrelated modal/fullscreen viewer or force all cards open/closed as a shortcut. If a materially different interaction/scroll architecture is necessary, contact parent with evidence before implementing.
3. Apply consistent behavior to tools, assistant fenced code, and the new inline Sub-agents tab within their own viewports. Replace the old modal with the two-tab session header; preserve state on tab changes and reset it on room changes. Reuse renderers for available nested content and retain a truthful fallback for flattened subagent output until structured telemetry is available. Avoid invisible hit blockers or permanently pinned titles after collapse/session change. At 320px/2x text scaling retain title/status and tappable controls without covering body text. Respect reduced animation preferences where applicable.
4. Add regressions that fail on code17: long last-message tool expansion (reverse list) and nested/normal code expansion; scroll through expanded contents and see active header; collapse pinned header; multiple cards; stream/status update not repeatedly dragging user; room changes clean up scroll/pinned state. Reuse real chat fixtures, not only a copied static Column. Format, focused tests, analyze, feasible full suite with only existing Linux/macOS scale exclusion.
5. Build personal ARM64 candidate code18 with unchanged app ID and signing, record hash/certificate and exact logs. Update App READABLE behavior/checkpoint. Worker does not install. Parent replays opening/scrolling/collapse on phone and captures screenshots + current-process logs before claiming device completion.

## Code18 device checkpoint and bounded follow-up

Parent installed code18 in place (Success, unchanged data inodes) and verified hash `0ec8c4440bc5b7684553fb6e545c8293c89793e0935317e4cd9c99a1b0aa5b46`. Actual Samsung screenshots `/tmp/72-expanded-top.png` and `/tmp/72-expanded-scrolled.png` show a long command heading aligned/pinned below the session tabs while its body scrolls. `/tmp/72-collapsed-after-pin.png` confirms collapse removes pinned slot. `/tmp/72-empty-subagents.png` shows explicit empty agent tab without composer. `/tmp/72-agents-expanded.png` shows real workflow fallback inside the inline Sub-agents tab; no fabricated children. New process log `/tmp/72-postfix-log.txt` has zero searched rendering exception matches. No prompts sent, agents stopped or pairing/preferences changed (home All filter used to inspect cached offline history).

Two observed visual defects require a bounded App follow-up before final visual acceptance:
- Tab selection exists only in Semantics, with both TextButtons identically styled. Add a clear selected-tab underline/background and selected/unselected text distinction, preserving 48px targets and semantics.
- `CompactOutputHeader` puts both title Expanded and status Flexible at equal flex, reserving roughly half the width for a short DONE label, needlessly truncating titles while leaving empty right space. Use intrinsic or bounded status width and give remaining width to title, preserving long statuses and 320px/2x safety. Re-test pin geometry after any change.

No other redesign authorized by this checkpoint. Build personal code19 after focused/full checks, parent installs/replays. Structured child telemetry remains explicitly unimplemented.

## Code19 follow-up / code20 continuation

`.orchestration/results/72-visual-followup.md` records the two bounded fixes, analyzer pass and 574 full-suite tests with the existing host-scale exclusion. Parent inspected the new theme-based selected-tab styling and intrinsic/bounded status width. Code19 was installed in place with unchanged data inodes; `/tmp/72-code19-main.png` and `/tmp/72-code19-agents.png` confirm active-tab underline/surface and improved title width; `/tmp/72-code19-agent-pinned.png` and `/tmp/72-code19-command-pinned.png` capture expanded headers. Fresh `/tmp/72-code19-log.txt` has zero searched rendering exceptions. Artifact hash is recorded in plan73. Code20 then adds user-requested IDE-like source rendering; see plan73 for installed-device evidence and its limited physical replay matrix. No claim of live recursive child telemetry, exhaustive streaming/theme/accessibility replay, or full LSP coverage.

## Definition of Done

- [x] Every session has Main / Sub-agents tabs; old modal navigation replaced.
- [x] Subagent output uses shared nested accordions for available code/tool/child structure; missing telemetry explicitly tracked.
- [x] Expanded heading initially aligns at top of correct content viewport.
- [x] Active expanded content retains an accessible, functional heading while reading.
- [x] Collapse/scroll-away/session-switch remove or hand off pinned heading correctly (automated regression coverage plus scoped phone collapse/scroll replay).
- [x] Code/tool/subagent behavior remains compact, wrapped by default, individually controllable.
- [x] Regression tests, analyze and signed code18 candidate verified.
- [x] Actual phone replay recorded with no rendering errors; limitations explicit.

## Próximos planos

Scout-backed additive structured subagent telemetry contract, only if needed to deliver the real nested agent/tool tree; Extension and App owners remain separate. Complete remaining plan71 device visual checks together with this device replay. Do not turn code18 installation alone into a claim that every live-streaming/theme/accessibility scenario was exercised.
