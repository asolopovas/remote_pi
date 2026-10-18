# 106 — Recover the active desktop conversation on the phone

## Context

Operator reports Unified Messaging CLI on the phone lacks the previous messages
visible in the desktop Pi. Phone Session info matches /home/andrius/src/msg-bridge
and that display name. Desktop native session metadata identifies
01a14c50-328d-7350-9623-23887fe53b28, created2026-10-18T00:01:26.669Z. Read-only
metadata inspection found155 message records plus18 custom_message entries in its
1.25MB saved JSONL; this is whole-file counting, not proof of the selected branch.
No conversation contents were printed or exported.

Source defects: index.ts session_sync projects an append-only in-memory
_messageBuffer, default-caps at30 events, never hydrates the native session branch,
and assigns session_started_at from extension startup time. Reload can therefore
lose the phone's replay source although native desktop history remains. App
SyncService._applyHistory replaces cached rows from each received history, ignoring
truncated/eos completeness. This can discard prior cached messages after a partial
replay. Existing full-history render must match the active native branch, not merely
buildSessionContext's compacted model context.

Model picker issue is separately delivered: code56 installed in place, exact APK
pullback/signature/UID verified; physical catalogue loads GPT6.1Sol without spinner
or model mutation. Preserve all105 scope/privacy/deadline protections. Do not reload
another host as diagnosis or change/clear a user's conversation.

## Expected structure

- Read the authoritative current native session through its trusted live SDK
  context; stable native session/entry identity across extension reload/reconnect.
  Do not accept phone paths, arbitrary native sessions or unrelated fork branches.
- Recover the full currently visible conversation with bounded authenticated pages
  and byte budgets, not an unbounded payload or a silently raised30-message cap.
  Include supported visible messages/tools/compaction/visible notices; exclude hidden
  system/control/private internals and preserve existing image/privacy rules.
- Stable canonical event IDs and deterministic order; no duplicates or loss when
  live events arrive during replay, compaction, reconnect or continuation pages.
- Truncated, empty/incomplete, unavailable, stale, interrupted or old-host tail
  snapshots must never destructively replace established history. Complete explicit
  new-session/reset semantics remain separate; never merge different conversations.
- Cursor/completeness/native identity, request correlation and every database await
  are fenced by peer/socket/room/native incarnation/selection/Owner grant. Enforce
  bounded traversal/pagination; no cursor cycles or authorization bypass.
- Preserve active-only MVP: this is not a historical-session browser/activation,
  pairing change, credential grant expansion, new service or default-model change.

## Steps and acceptance

1. Bounded source scouts establish native SDK0.79/1.3 branch/header/identity APIs,
   projection/current wire/legacy compatibility and App reconciliation/scope behavior.
   Review a minimal bounded protocol/recovery design before implementation.
2. Implement scoped host history hydration/pagination with synthetic saved native
   sessions; App non-destructive replay/cache reconciliation and earlier-page UI.
3. Regressions: >30 messages, cold phone/reconnect/reload, stable IDs/native identity,
   active branch vs other forks/pre-compaction context, visible vs hidden entries,
   partial/empty/oversize/failed page, live appends, pending echoes, cursor cycle,
   wrong peer/room/Owner/session/ABA, lock expiry, database/disposal races and legacy
   snapshots. Assert native files/history are not rewritten or truncated.
4. Independent security/correctness review; fresh isolated offline Node/App
   typecheck/analyzer/focused/full gates under machine lease; complete immutable host
   C and fresh same-signer App57 only after source review.
5. Deliver App safely and activate only a freshly verified idle child-free eligible
   host, preserving all user jobs. Physically compare identity/counts/old-message
   presence on the phone without logging conversation contents or submitting prompts.

## Definition of Done

- [ ] Native history remains intact; replay uses stable current-conversation identity.
- [ ] Full bounded recovery and non-destructive partial/legacy reconciliation pass.
- [ ] Scope/privacy/continuation/live-update regressions and independent review pass.
- [ ] Current signed delivery and phone recovery outcome/limits recorded.

## Next

Complete outstanding plan103 phone API3/new-agent default acceptance only when
private user authorization permits. No PIN capture, paid model turn, Stop or forced
restart is implied; main876568 and its existing mbot child must remain untouched.
