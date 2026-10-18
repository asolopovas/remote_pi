# 105 — Responsive, session-bound phone model selection

## Context

Operator reports the phone's model control shows a loading icon and cannot change
models. Samsung is currently absent from ADB, so no live-screen diagnosis is claimed.
Source confirms ActionsRepository handles action_error but ignores correlated generic
error responses used for locked/expired managed sessions. Its timeout covers a
Completer but _dispatch first awaits channel.send; a stalled send can outlive that
timeout. Model catalogues are also cached against the current response-time session,
not the request's original target. Verify the actual production path in regressions.

Plan103 exact-default API3 runtime remains published for future loads; do not stop,
restart or reload user jobs or change models to manufacture acceptance. The old
managed mbot agent must remain untouched. Completed plans have been removed at the
operator's request; do not restore them.

## Expected structure

- Bound model-list/model-set completion, including stalled sends, disconnects and
  channel close/error. Correlated scoped generic errors settle immediately with
  actionable inline feedback, not a persistent spinner or chat-history pollution.
- Bind pending actions, replies and caches to original peer/socket/room incarnation
  and selection generation. External selection/ABA invalidates, never retargets or
  caches A's catalogue as B's. No automatic model-set replay or false success.
- Model failures leave usable Retry/read-only reconciliation or exact-parent Check
  access/Unlock recovery. Never retain/replay PIN, guess a parent, bypass expiry or
  widen grants. Existing API2 agent controls/model selection stay supported.
- Only list models actually supported by the selected agent. Do not invent Sol for
  an old runtime or transplant a descriptor. No automatic model switch/Stop/prompt.

## Steps and acceptance

1. Reproduce generic locked-error handling and unbounded/stale async paths using
   production repository/channel/widget fixtures; identify host compatibility limits.
2. Correct minimal App implementation, inline error/retry/access flow and action
   scoping, preserving existing launch/removal/recovery protections.
3. Cover locked/expired errors, stalled/failed send, no reply, close/error, reversed
   refresh replies, scope/ABA/incarnation/disposal changes, wrong replies and positive
   model selection with exactly one explicit mutation and no automatic replay.
4. Reconcile the verified host ABI dependency: cached SDK0.79 refresh is synchronous,
   while installed SDK1.3 refresh returns a Promise. Await either form before catalogue
   reads/model selection, handle rejections with correlated safe errors and fence
   context/incarnation across every await. Host source work is separately owned;
   no existing root may be reloaded to test it.
5. Independent review; fresh analyzer/focused/full serial offline gates under machine
   lease. Build a fresh same-signer higher-code APK after source review. Device
   installation/physical acceptance depends on an available authorized transport.

## Definition of Done

- [x] Loading reaches a bounded success/error and valid lists/selections still work.
- [x] Action scope/cache/error and no-replay regressions pass.
- [x] Actionable access recovery preserves actual-parent/PIN/security boundaries.
- [ ] Independent review, release and physical outcome/limits recorded.

## Delivery progress — 2026-10-18

Source review OK after the pre-discovery incarnation gap and misleading re-entry
copy were corrected. UI errors are inline and bounded; invalid scope offers Close
and explicitly requires returning to sessions/reopening the chat. A stale VM never
renews its authority. Valid-scope Retry only reloads the catalogue. Locked/unavailable
errors direct explicit Session info → Check access → Unlock launching host, retaining
existing exact-parent recovery rather than inventing an automatic PIN flow.

Current App1092 full serial passes; fresh independent release464 focused passes and
lib/test analyzer clean.286-entry UX manifest hash
`08eb41eddbf5dd3778f46ef5b070980d97023bfdfc74b1a125989aab46cda08e`.
Fresh ARM64 code56 APK, expected signer and AOT verified;650 App/Node sources
unchanged through packaging:
`app/build/releases/code56/accepted/code56.apk`, SHA256
`b20cbca4f68e915101619c9d291f6fab29d274467d7056f532539868746d6dcb`.
**Not installed:** Samsung absent from USB and paired ADB mDNS discovery. Code55
remains the last verified installed app; actual phone failure/acceptance unknown.

Host B independently built/tested in a private full layout:294 focused,119 managed,
1118 full passes/3 skips, real network-isolated Pi1.3 context/registry fixture with
fake mutation only. Full26219-file/765-symlink package independently copy-verified
and published at
`~/.pi/agent/npm/node_modules/remote-pi/.releases/model-actions-59c3ca45c8186da9`.
Root manifest `5b2f33729ce16b5c7052d81f54bffe2cc3ecb48f1ce2d68e85dfeb97c0a1ce17`;
private runtime manifest unchanged. Prior A/older releases retained.

A fresh preflight finally found msg-bridge2812854 idle, ready, no scoped background
executions and no managed descendants. Only its extension /reload was executed;
B native imports and unchanged PID/native session verified. Main876568 and its
mbot2421411 retained their original start ticks and ancestry. No Stop, process
restart, model selection or paid model turn. Own native slash-command queue entry
q14 was removed without retry after execution (watchdog expected a model turn).
Publication/reload proof is **not** owner-endpoint API3 or phone new-model acceptance.
Receipts: code56/accepted/host-B-provenance and parent-delivery-status.json.

## Next

Complete code56 installation/physical acceptance when the authorized phone transport
returns, then verify plan103 API3/new-model flow privately on the phone. Access lifetime
remains unchanged; no new service, dependency download or credential access.
