# 71 — Device-observed rendering, project identity and terminal appearance

## Contexto

Follow-up explicitly requested after code16 installation: the phone has confusing empty views, sessions cannot be identified by project/folder or working agent, and colors/fonts should resemble the user's current terminal. User authorized ADB inspection. Prior tests did NOT establish device correctness; do not repeat acceptance without phone evidence.

Root is plan-only. App-scoped workers implement; parent owns ADB navigation and device validation. Never launch/use Cockpit or cmux. Never send chat prompts, delete sessions, clear app data, change pairing, or stop agents during inspection. Keep existing uncommitted plan70 work.

### Evidence

- Device: Samsung SM_S926B, serial `R5CXB2PGC2H`, personal package `io.github.asolopovas.remotepi.readable`, code16 installed.
- `/tmp/remote-pi-phone-before.png` and `/tmp/remote-pi-blank-repro.png`: try-now chat with a large blank region above rendered assistant text and an edit accordion. Blank space alone is not proof of a layout bug (short reverse list can bottom-align); investigate alongside logs.
- `/tmp/remote-pi-device-log.txt`: at 10:07:24 actual `Null check operator used on a null value`, first frame `RenderSliverMultiBoxAdaptor.childMainAxisPosition`, followed by paint and repeated framework exceptions. Inspect dynamic list reorder/streaming and keepalive lifecycle, not only static cards. Do not suppress exceptions.
- `/tmp/remote-pi-home.png`: Online 4/All 5 with names continue, remote pi, try-now, try-now#3; only model subtitle and unlabeled status dots. Folder/working directory is absent.
- `/tmp/remote-pi-current-chat.png`: selected remote pi is Online but displays Nothing here. `/tmp/remote-pi-room-info.png` reveals its path `/home/andrius/dotfiles`, not inferable from the title. Distinguish genuinely empty history, syncing, and failed rendering; do not invent history or claim all empty states share the rendering cause.
- `RoomInfo` already includes cwd/name/roomId/startedAt/working/model. No protocol expansion needed to show project identity and observed status.

### Terminal reference (read-only, do not alter desktop)

`~/.config/alacritty/alacritty.toml` points into `/home/andrius/dotfiles/.config/alacritty/`. Current environment is TUIOS within Alacritty. TUIOS config has no custom palette override. Alacritty:
- background `#14191F`, foreground `#FFFFFF`, ordinary pale foreground `#AEC2E0`
- teal `#269685`, green `#50FA7B`, red `#FF5555`, orange `#FFB86C`
- light cyan `#8BE9FD`, blue-gray `#6272A4`, selection `#44475A`/`#F8F8F2`
- font `FiraMono Nerd Font`, Regular (desktop size 12; do NOT copy physical size blindly to phone)
- Local font source `/home/andrius/.local/share/fonts/FiraMono/`: FiraMonoNerdFont-Regular.otf, Medium.otf, Bold.otf and LICENSE. Verify redistribution terms before bundling. No download required. Keep branding Inter and phone accessibility/text scaling intact.

## Estrutura esperada

Three sequential exclusive App component owners (no overlapping writers), then an integration verification/build gate:
1. Chat rendering correctness: chat list/streaming/keepalive code and focused tests. May adjust subagent list only if same root cause. No home or theme edits.
2. Project identity: home tiles/title helper/status, routing/chat title consistency if necessary, and tests. No theme tokens or rendering lifecycle edits; preserve prior fix.
3. Appearance: theme tokens/font assets/pubspec font entries and theme/font tests; preserve home/chat behavior.
4. Integration: read handoffs, run combined validation, update App delivery documentation and build candidate code17. No broad new features. Parent replays phone inspection before claiming device success.

All workers read App/layer instructions and write distinct `.orchestration/results/71-*.md` reports. No commits/staging/push or published releases. Native subagent completion replaces pane notification. Source boundaries and durable handoffs make sequential reuse of the dirty App cwd explicit.

## Passos com critério de aceite

### 1. Reproduce and correct rendering

Trace sliver null offset with realistic ListView.separated reverse-list updates: streaming row insertion/removal, persisted assistant replacement, history reload, kept-alive expanded/collapsed items, tool-to-subagent extraction, duplicate ids and session switches where supported. A real reproducer must fail before the fix. Check SDK callback contracts instead of guessing separator index multiplication. Preserve collapsed defaults and wrap-on-open.

**Aceite:** targeted regression demonstrates prior failure and now passes; no fake padding compensation or swallowing framework errors. Record explanation and distinguish normal bottom alignment from broken painting. If root cause cannot be demonstrated, report evidence and escalate rather than declare it fixed.

### 2. Recognizable sessions

Keep flat existing peer/session list and filters, no deletion or silent hiding of valid sessions. Primary label is actual project folder basename when cwd exists; retain user/session name as secondary context, especially duplicate folder sessions. Show readable working path (handle Unix/Windows paths, preserve full original in detail), with explicit Working / Online · idle / Offline or Reconnecting derived from existing connection facts. Model is tertiary, not the only subtitle. Distinguish duplicate project sessions using session name or short room id when names also collide. Never infer agent role or last activity from model/start/paired timestamps. Make chat heading/session info consistent without mutating remote session names.

**Aceite:** tests for duplicate folder names, generic session labels, missing cwd, Windows paths, working/idle/offline/reconnecting, long paths and large text. Existing filters/navigation remain stable. Empty chat wording should explicitly say no messages available and not suggest that online guarantees content; loading/failure distinctions only when existing state supports them.

### 3. Terminal-inspired dark palette/font

Use observed terminal colors through semantic theme tokens: blue-gray background, readable pale text, restrained light-cyan/teal accent, green success, orange warning, red errors. Dark cards/fields need distinguishable surfaces and readable borders, not giant blank black boxes. Check contrast; a literal low-contrast ANSI token need not be used as tiny text. Bundle local licensed Fira Mono fonts with regular/medium/bold mappings and preserved LICENSE; fallback/synthesized italic must be deliberate. Keep Inter wordmark and large/XL scaling. Keep light theme legible and user theme choice intact; do not rewrite desktop configs.

**Aceite:** theme/font tests, readable status/header/path contrasts, no missing fonts offline, no new dependencies, no unrelated branding redesign. Native surface: HTML detector is not applicable.

### 4. Integrated validation and device gate

From App cwd use installed SDK:
`PATH=/home/andrius/.local/share/flutter-sdk/flutter/bin:$PATH`, `ANDROID_HOME=/home/andrius/Android/Sdk`, `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`.

Format changed files, focused suites, `flutter analyze --no-pub`, full suite with documented pre-existing Linux/macOS host-scale exclusion. Build ARM64 release-mode personal APK code17 using unchanged appId/signing; record certificate/hash. LSP coverage unavailable must be stated, not called clean. Parent performs authorized inspection and obtains any needed installation approval, then checks real home sessions, chat history scrolling, individual accordion expand/collapse, wrap, subagents and post-fix process logs. No agent commands/messages sent during UI verification.

## Definition of Done

- [x] Device rendering error explained with regression and fix, not hidden.
- [x] Session tiles identify actual project/path and observed working state.
- [x] Duplicate/unnamed sessions remain distinguishable without data deletion.
- [x] Dark colors/font match inspected terminal reference with mobile contrast/scaling.
- [x] Combined tests/analyze pass; signed personal candidate built with recorded hash.
- [ ] Full phone verification completed (partial replay below; expanded-heading behavior requires plan72).

## Device checkpoint — code17

Parent installed code17 in place during the authorized ADB correction/inspection workflow. `adb install -r` returned Success; package inspection confirmed version 1.2.0/code17 and unchanged user data inodes. SHA-256 `89dd2354558eabe9fbe3fa34d8cfa29a5f21dbbb73b08c89e47f92127ddf21df`. Existing certificate unchanged per integration verification. 81 focused / 568 full tests passed; analyzer clean. One documented host-scale test excluded; full LSP coverage unavailable.

Actual phone screenshots `/tmp/71-start.png`, `/tmp/71-home-now.png`: terminal palette and Fira Mono visible; project lcl-manager-bot and dotfiles paths now identifiable; same-project sessions retain distinct name/short-id; Working and Online · idle labels visible. Online count remains four; offline count grew from one to two naturally during the workflow, not a deletion/filter change.

Parent navigated existing lcl-manager-bot/continue and dotfiles/try-now histories, scrolled repeatedly in both directions, used Latest, expanded commands and opened the existing subagent sheet. Content now paints throughout inspected history rather than the earlier broken sliver output. `/tmp/71-try-now-history.png`, `/tmp/71-tool-expanded.png`, `/tmp/71-subagents-collapsed.png`, `/tmp/71-subagents-expanded.png` capture this. Fresh code17 process logs in `/tmp/71-postfix-log.txt` contain zero matches for Null check, childMainAxisPosition, RenderSliverMultiBoxAdaptor, performRebuild, Exception, E/flutter, or Another exception at the checkpoint. No prompts were submitted, agents stopped, data cleared, or pairing/preferences changed. Clipboard and optional horizontal scrolling were not device-replayed; automated coverage remains distinct.

**Device feedback found another real UX issue:** long accordion expansion in the reversed timeline leaves its heading offscreen above the viewport (`/tmp/71-try-now-expanded.png`). User now explicitly requests heading at top on open and visible while reading. This is plan72, not solved by the row-identity fix. Full device acceptance remains open. No Dark/Light/XL preference toggling was performed in this replay; no claim of full visual matrix coverage. Parent left phone on home after inspection.

## Próximos planos

Only if supported by evidence: richer last-message previews/activity or true background-agent hierarchy using explicit data. Do not fabricate those in this UI pass.
