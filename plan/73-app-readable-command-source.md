# 73 — Render command source, not escaped JSON

## Contexto

User observed expanded commands containing literal-looking `\n` JSON escapes and asks to see the command as rendered/formatted code instead. Current `ToolRequestCard._formatArgs` only returns plain bash source if args has exactly one field; normal commands also include timeout and therefore fall through to JSON serialization. Screenshot `/tmp/72-expanded-top.png` documents that bug in readability.

Code19 is already installed in place and device-checked for clear selected tabs, wider headings and agent/command pinning; `/tmp/72-code19-main.png`, `/tmp/72-code19-agents.png`, `/tmp/72-code19-agent-pinned.png`, `/tmp/72-code19-command-pinned.png` and fresh logs with zero searched rendering exceptions. Hash `e3ecedd3d6c27e17ec5d508bcd47f7f6213458defa9a475287d091b88f81c9e2`. This plan is the additional user-requested source presentation, not a rollback of accordion/state functionality.

## Estrutura esperada

One scoped App writer for command presentation and related tests only. Root parent owns plan and ADB validation. Preserve all plan70/71/72 dirty work, terminal styling, tabs, stable identities, sticky headings, collapsed defaults, wrap-on-open and truthful subagent fallback. No execution/protocol changes, commits/staging/push, Cockpit/cmux or worker device actions. Dependency exception for the explicit IDE-like syntax-color requirement: if no incumbent highlighter exists, add one narrowly scoped mature pure-Dart syntax-highlighting dependency with its necessary lockfile resolution, after checking official package docs/license. Do not install toolchains, upgrade unrelated dependencies or download unrelated assets.

## Passos com critério de aceite

1. Known command tools (bash/powershell, namespaced variants where existing names are supported) render the actual string `args.command` regardless of other metadata fields. Known script tool such as codemode renders `args.code` source when present. Use existing code viewport with monospace, preserved line breaks/indentation and default wrap. Do not execute, reformat syntax, change quoting, or blindly replace literal backslash-n sequences: JSON has already been decoded by the protocol; actual newlines and intentional `\\n` must remain distinct. Malformed/unknown argument shapes retain safe readable fallback.
2. Primary command copy action labeled **Copy command** copies exact original source (not serialized args, metadata, or result). Preserve full original args/results/errors via separate clearly labeled **Details** / existing appropriate output disclosure and copy-all/details controls, without duplicating the entire source in the default view. Results/errors remain selectable and distinguishable from command source. Avoid hiding useful output unintentionally, and preserve write/edit raw payload and diff display.
3. Subsequent user clarification makes **IDE-like syntax coloring** part of acceptance, not optional. Use a shared source-code renderer with language label and theme-consistent token colors for shell/PowerShell and JavaScript/TypeScript scripts; reuse for assistant/subagent fenced code and write content when language is known. Current App has no highlighter (gpt_markdown codeBuilder currently uses plain Text). A mature pure-Dart dependency such as `highlight` may be added after checking official docs/API/license; this exception is recorded above. Do not hand-roll a broad regex lexer or run formatters/interpreters on source. Preserve exact source in TextSpan/plaintext extraction and copy; use plain fallback for unknown languages or parser failures and bound highlighting for huge input. The primary review shows **Command** (or Script), **Output**, and **Error** separately. Wrapper metadata is secondary Details. True JSON output may remain JSON, distinct from serialized wrappers around executable source.
4. Tests: multiline shell with timeout/metadata shows line breaks and indentation; exact command copy; intentional literal backslash sequences preserved; codemode source; malformed non-string command and unknown tools safe; original details remain recoverable; pinned heading/copy and wrap/scroll work with new controls; 320px/2x no overflow. Format, focused tests, analyze, feasible full suite with only existing documented host-scale exclusion.
5. Build personal ARM64 code20 with unchanged applicationId/signing, record hash/certificate/version. Update READABLE accurately. Parent installs/replays actual command with metadata on phone; no prompts submitted or shell commands executed by tapping UI during verification.

## Definition of Done

- [x] Command/script source renders directly with original newlines/indentation and IDE-like syntax colors/language label.
- [x] Command, output, error and optional metadata are clearly separated, not an API dump.
- [x] Copy command preserves original bytes and metadata/results remain accessible separately.
- [x] Literal escape sequences, malformed args, other tool cards and sticky behavior covered by tests.
- [x] Analyze/tests pass; signed code20 candidate built and hashed.
- [x] Phone replay confirms rendered command readability and no new rendering errors.

## Parent review and device evidence

Parent read the completed result `.orchestration/results/73-readable-source.md` and independently inspected source extraction, source highlighting/lossless fallback, shared Markdown integration and copy/viewport controls. No pending supervisor requests. Worker reports 36 focused / 578 full tests, analyzer clean, documented pre-existing host-scale exclusion only. No separate reviewer agent was launched; parent performed source review. LSP coverage is not claimed.

Verified artifact SHA-256 `c2f6b23ae158442a35fad242cd3d9cda7063fa889c1aef007e8e2c4f87311eb2` and installed in place successfully on Samsung `R5CXB2PGC2H`, package `io.github.asolopovas.remotepi.readable`, version 1.2.0/code20. Data inodes remain `401942` / `375935`; no data reset/uninstall/pairing changes. Source review and tests verify exact clipboard bytes; parent did not overwrite the personal device clipboard for testing.

Device replay in existing cached history:
- `/tmp/73-codemode.png`: JavaScript source with colored strings/keywords/numbers, two actual source lines (wrapped visually), separate Output.
- `/tmp/73-code-scrolled.png`: script header remains pinned as output scrolls. Actual tool-generated JSON inside output remains verbatim, not heuristically unpacked.
- `/tmp/73-bash-source.png`: real multiline `python3 - <<'PY'` Bash command, indentation/newlines and colored source instead of serialized args wrapper.
- `/tmp/73-bash-scrolled.png`: pinned heading, readable source ending, distinct plain Output and collapsed Details.
- `/tmp/73-details.png`: optional original argument payload is reachable, deepest Details heading takes over pinned slot. A phone call interrupted immediately afterward; parent stopped all device interaction. Final Details-collapse replay was NOT completed or claimed.
- `/tmp/73-code20-log.txt`: fresh current-process log has zero matches for the searched rendering exceptions (`Null check`, sliver/rebuild, `Exception`, `E/flutter`). This is scoped evidence, not proof of no possible errors.

No chat prompts were submitted or tool executions triggered; no agents stopped, preferences/theme/font scale changed, commits/staging/push performed. Device gate above covers current dark-theme/default-scale command readability and scrolling only. Light/Dark token colors and narrow/2x behavior are automated-test coverage, not fresh physical-device coverage. Remaining optional phone matrix (theme/scaling, clipboard, final nested collapse) is explicitly unverified. Unknown languages and source over 24k code units are exact readable plain text; this is lexical highlighting, not semantic IDE analysis or automatic formatting.

## Próximos planos

Actual structured per-child telemetry remains the separate limitation from plan72/scout; do not claim this formatting change solves it.
