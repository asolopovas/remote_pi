# 70 — App: compact commands and subagent output

## Contexto

The user has Remote Pi installed on their phone and wants a more compact conversation: commands/code and subagent output should be collapsed accordions, with short action titles and visible status indicators. This is the Flutter mobile app, not Pi's terminal. The user explicitly rejected Cockpit; do not install, launch, or use it for this work.

Current source evidence:
- `app/lib/ui/chat/widgets/tool_request_card.dart`: status labels exist, but commands/diffs always occupy the body; tool results are not displayed here.
- `app/lib/ui/chat/widgets/code_viewport.dart`: copy/wrap controls exist but no collapse control.
- `app/lib/ui/chat/widgets/subagent_panel.dart`: individual subagent expansion exists and defaults to the persisted `collapseSubagents` preference; headers use two lines and lack status icons.
- `app/lib/ui/chat/chat_page.dart`: recognized subagents are separated into a bottom sheet, accessed through a count-only link.
- `app/lib/data/preferences/preferences.dart`: subagents already default to collapsed. Respect existing explicit preferences.

## Estrutura esperada

Owner: **App**, with one scoped writer rooted in `app/`. This is a single coupled chat-presentation seam (shared accordion header, tool/code/subagent renderers and their tests). Parent writes plans only; the App worker implements and validates from its own cwd. No transport, execution, pairing, approval, or harness changes. No dependencies or speculative status fields.

Use incumbent colors/typography, compact visual density with accessible tap targets. Shared compact header where practical: disclosure chevron, icon/colored indicator, action title, and a readable status label. On narrow screens the title may ellipsize or occupy one additional line; status must remain visible. Color is not the sole status cue.

Examples:
- `▸ [running indicator] Bash · git status  Running`
- `▸ [green check] Read · lib/main.dart  Done`
- `▸ [red warning] Bash · flutter test  Failed`
- `▸ [green check] Scout · Review files  Done`

Titles are deterministic summaries of the actual tool name/arguments or agent task, not generated claims about intent. Normalize whitespace for headers without altering the original content. Missing/unknown arguments fall back to the tool name. Fenced code blocks show a language/code title and line count, **not** an execution status.

## Passos com critério de aceite

### 1. Collapsed command cards

Tool cards default to collapsed for new/history entries; the header remains visible while running and after completion. Expanding reveals full original arguments/command/diff, available result, and errors. Preserve existing diff styling, selectable/copyable content, and wrap behavior. Copying uses full content, never the abbreviated title. Status changes do not unexpectedly expand or collapse a card the user toggled. Preserve expansion across ordinary scrolling/rebuilds using stable message identity; do not leak expansion between peers/sessions.

**Aceite:** widget tests verify initial collapse, expansion, collapse, pending→completed/failed updates, full multiline content on expansion/copy, malformed/unknown arguments, and stable identity.

### 2. Compact code blocks

Make assistant fenced command/code blocks individually collapsible by default through `CodeViewport`/`AgentMarkdown`. Keep surrounding assistant prose fully visible. Expanded blocks retain full-content copy and **wrap text by default** (explicit user update). Apply default wrapping to command/code/diff/result/subagent detail text so long lines fit phone width; retain an opt-in Scroll toggle per code viewport and preserve that choice through updates/scrolling. Collapsed header titles remain bounded/ellipsized. Do not change tool-card content ownership inadvertently when `CodeViewport` uses a custom header. Avoid rendering expensive hidden bodies where possible.

**Aceite:** Markdown/code viewport tests verify visible title and line count, hidden body until tapped, full-content copy, default wrapping after expansion, opt-in horizontal scrolling and toggle persistence, selection, and streaming completion without unwanted toggle resets. No fake Running/Done label on plain code examples.

### 3. Subagent headers and output

Apply the same title/status convention to existing subagent accordions. Keep the existing dedicated sheet rather than add a competing panel. Improve its chat launcher with compact observed-state counts/indicators so the user can see activity without opening the sheet. Respect the existing persisted Collapse subagents choice and per-item expansion.

Recognize launch shapes actually emitted by installed subagent tooling where supported by current `ToolEvent.args` (single agent, workflow and relevant parallel/batch shapes); control-only calls remain normal tool cards. Add recognition tests. Never label a detached asynchronous child Done merely because its launch tool completed: use Launched when the connection has no child completion/progress, and preserve the existing explanatory note on expansion. Only claim live status when data actually supplies it.

**Aceite:** tests cover collapsed/full output, success/failure, detached launch semantics, supported launch shapes, control-call exclusion, existing preference behavior, and launcher counts.

### 4. Verify in App workspace

Read `app/CLAUDE.md` and applicable layer instructions. Run formatting, focused widget/unit tests, and `flutter analyze` from `app/`, then the full test suite if feasible. If Flutter is unavailable, inspect documented local SDK/container tooling; do not download a toolchain or claim tests passed. Record exact blockers and commands. Parent does not run subproject builds/tests from the monorepo root.

A release or installation on the user's phone is a distinct delivery step: do not publish, tag, upload, change signing/version, or replace the installed app without an approved release/install path. Report whether a tested artifact was produced or only source changes exist.

**Aceite:** concise App report with changed paths, commands/results, validation gaps, and phone delivery needs. No Cockpit/cMux processes, no commit/push, no unrelated cleanup.

## Definition of Done

- [x] Commands/diffs/results collapse by default with truthful action/status headers.
- [x] Fenced code blocks collapse individually without hiding assistant prose.
- [x] Subagent accordions and launcher show compact, truthful observed status.
- [x] Full content remains accessible and copyable; expansion is stable during updates/scrolling.
- [x] Narrow-screen, accessibility, preference and launch-shape tests cover the behavior.
- [x] Focused tests, analyze, and feasible full validation reported with evidence.
- [x] Phone installation/release status explicitly reported, not implied by source changes.

## Verification and delivery checkpoint

Parent reviewed the final renderer diff, shared header, code/subagent regression tests, App report, validation log tails, and artifact hash. App worker ran 53 focused tests and 557 full-suite tests successfully; the full run excludes the documented pre-existing macOS sound-scale expectation on Linux. `flutter analyze --no-pub` found no issues. LSP coverage was unavailable, not claimed clean. No source/test blocker identified by the parent; no separate independent reviewer was run.

Final local candidate: `app/build/app/outputs/flutter-apk/app-release.apk`, personal fork `io.github.asolopovas.remotepi.readable`, version 1.2.0/code 16. Worker verified the unchanged Android debug signing certificate. Parent verified SHA-256 `2dca8d8c9514cfc919e3bf2f7d641fb4a7af386c7b89172a299ede80119dc17d`. Expanded text wraps by default; horizontal scrolling remains opt-in.

**Installed after explicit user approval.** Parent discovered one authorized Samsung SM_S926B device, rechecked the APK hash, confirmed existing version code 15, and ran `adb -s R5CXB2PGC2H install -r app/build/app/outputs/flutter-apk/app-release.apk` → `Success`. Post-install package inspection confirmed version 1.2.0/code 16 and unchanged user data directory inodes. No uninstall or data clearing. Phone visual verification remains pending; no publication occurred. No commits/staging, protocol changes, or Cockpit usage. The earlier worker report and `app/READABLE.md` describe the pre-install candidate checkpoint; this entry records the subsequent approved installation. See `.orchestration/results/70-app-compact-output.md` for build/test evidence.

## Próximos planos

After validated implementation: device visual verification and delivery through the user's existing Android/iOS distribution channel. Rich asynchronous child progress is a separate protocol-backed task only if current transport cannot provide it; do not invent it in UI.
