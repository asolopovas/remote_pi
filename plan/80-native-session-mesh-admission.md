# 80 — Explicit current-session/current-task mesh admission

## Context

Continue the user's plan77 isolation requirement: unrelated mesh material must not enter a native Pi conversation, its persisted/replayed history or attached mobile chats. Delivery, addressing, same cwd/account/files, names, role flags and reply IDs are not relationship authorization. No foreign conversation inspection or retroactive transcript deletion is authorized.

Read-only child `61c13f49-9b32-49cc-824a-cef9f5d05805` completed the source-backed admission contract. Report: managed workflow `04ceee7a-c1a2-4a59-a331-304fa10bd87b/extension/77-admission-contract.md`. It found THREE distinct holes: `_deliverMeshMessageToAgent` broadcasts body to mobile before native admission; SessionPeer resolves application requests by `re` alone and returns the body as native tool content; queued drains lack native/task authority stamps. Fixing only the first native send is insufficient.

## Expected structure

One future exclusive Extension writer; Parent owns contract, review and runtime activation. Native pi-subagents completion/supervisor routes remain untouched and independently operational. Related local mesh connectivity/locks must remain; positive body sharing must have an explicitly approved current-task/current-native-session grant, not a cwd-wide exception. Existing broker addressing/audit stays transport-only and body-free.

Current five-field mesh envelope has no authenticated sender-native-instance/task grant. Existing native host-owned child metadata belongs to package-native supervisor/completion channels, not arbitrary mesh envelopes. A role environment flag or session-file parent header cannot manufacture lineage. A positive authenticated opt-in seam needs explicit UX/issuer/credential-distribution approval; do not silently introduce it or disable all useful related coordination and call the feature complete.

## Steps and acceptance

1. Approve minimal ephemeral grant lifetime/UX and trusted issuer/adapter ownership. Scope identifies current native UUID, runtime epoch and explicit task epoch; starts with no grants, never persisted/reconstructed from conversation or LocalConfig. Native host may authorize only children it actually owns. User-authorized sharing must bind exact intended peer session instance/channel/direction/expiry and bounded usage.
2. Sole Extension implementation centralizes admission before BOTH application subscriber dispatch and pending-request resolution. Retain exact trusted broker controls/ACK/transport-error demux separately; sender-controlled body.type is not broker provenance. Revalidate captured authority before every mobile synthetic event, native custom send/wake, requeue and tool-result return. Reject without body logging, fallback injection, inbox persistence or automatic replay.
3. Synchronously revoke before shutdown awaits, task finish/expiry, committed branch changes and replacement. Runtime/task generations protect A→B→A and same-UUID reload. Clear old queues and reject requests with metadata-only errors. Reply requires valid scope/grant plus exact expected sender/instance; re alone never opens authority. Bounded replay ledger fails closed when full.
4. Positive sharing requires an owner-issued authenticated capability/equivalent absent from today's envelope. Prefer targeted-only first; legacy broadcasts/multicast cannot become cwd-based grants. Credentials must never enter model/tool arguments, mobile body/history or logs. Use existing primitives, no custom crypto/new dependencies. Propose any application-envelope/native-adapter contract explicitly before implementing that seam.
5. Synthetic tests cover unrelated same-cwd/different-project senders, role/name claims, matching/wrong reply IDs, delayed/duplicate/timed-out replies, revoked busy queues, session/branch replacement and grant expiry/replay limits. Positive native supervisor/completion tests are distinct from granted mesh body tests. Preserve presence regressions. Cached toolchain only, independent review and exact compiled diff; no deployment/reload on child or peer request.
6. Parent approves safe installed activation separately; busy roots are not automatically restarted/reloaded. Report source protection versus loaded-runtime protection and device/consumer acceptance separately. Do not claim old persisted contamination was cleaned or mobile native identity/cache/queue epochs solved by this ingress gate.

## Definition of Done

- [x] Source-backed multi-ingress/queue audit completed without foreign content inspection or mutations.
- [ ] Explicit positive-sharing grant contract, native adapter ownership and implementation scope approved.
- [ ] Sole Extension writer implements complete pre-sink admission and lifecycle/reply gates.
- [ ] Synthetic positive/negative matrix and independent review pass.
- [ ] Reviewed loaded-runtime activation accepted without job/global-settings disruption.
- [ ] Actual permitted versus unrelated delivery behavior verified at the relevant native/mobile boundaries.

## Next plans

Plan77 authoritative branch history and App selection/cache/queued-send identity remain separate. Standalone Claude MCP mesh consumer has its own body-buffer/wake path and is NOT silently covered by a native factory fix; assign that consumer explicitly if required. Plan81 desktop/mobile display naming does not establish related-work admission.
