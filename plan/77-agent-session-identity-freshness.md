# 77 — Distinguishable agent sessions with verified latest messages

## Context

User reports phone sessions do not match the latest PC agent message and names make agents difficult to distinguish. Host/TUIOS restart during plan75 restored old panes while new live panes received different IDs; four live Pi conversations were verified separately from restored inactive panes. TUIOS Pi hooks are current and report Working/Done; default coordinator/subagent model presets are coherent. Two live dotfiles panes had identical manual names; parent changed only the second to `Pi · dotfiles (2)`, without changing the Pi conversation, model, permissions or focus. This desktop label alone does not prove the mobile session identity or fix stale content.

Plan71 project-first names and plan74 discovery recovery are accepted baselines. User explicitly asks to improve distinguishing names; retain the flat room/session model, persistent pairing and sender/room guards. No inferred main/worker/reviewer roles, new daemon, auto-resume or name-based routing.

## Expected structure

Start with a read-only producer/consumer/live-identity audit. Record actual TUIOS window→Pi conversation ID→registered room→phone selection plus completed assistant message timestamp/fingerprint. Human labels are display-only; canonical paired PC identity and room remain routing authority. Different conversations in one cwd remain separate. Clearly distinguish live current rooms, offline cached rooms, requested/received history and Working status; none implies fresh history by itself.

## Project/native-session isolation — reported user requirement

The audit/monitor peer relayed an explicit user requirement on2026-10-11: work in remote-pi must not mingle unrelated agents' messages. Incorporate this as acceptance scope; the coordination message does not authorize implementation, deployment/reload, global configuration changes or a new protocol. Same account, machine, paired host, project/cwd, agent name or targeted address is not by itself a related-work boundary. Verified native child lineage or explicit user-approved, task-scoped sharing can establish related work; a sender's claimed role/relationship cannot.

Keep three distinct paths:
- **Targeted mesh messages:** successful addressing/ACK proves delivery, not permission to inject content into a native conversation. Separate transport delivery/inbox visibility from relationship admission, LLM-context injection, persisted transcript and later replay. Unrelated or unknown-relation material must not automatically enter remote-pi's conversation or shared-work history. Preserve allowed direct coordination for explicitly related work, not an inferred cwd-wide allowlist.
- **Mobile selected-chat history:** canonical paired PC/room authority is necessary but not sufficient for native conversation identity. Derive snapshots from the selected SDK session/branch; bind history requests, responses, cache replacement and queued outgoing work to the intended conversation/selection epoch. Same-process/same-room native-session replacement, A→B→A and late callbacks must not substitute an unrelated native transcript or flush an old conversation's queued prompt into a new one. The current wire does not expose native Pi UUID; any missing identity/epoch contract must be proposed explicitly, not silently invented or claimed solved by names/request IDs alone.
- **Deliberate foreign-chat inspection:** inspecting another selected mobile chat is not itself a demonstrated transport leak, but it is a separate, specifically authorized diagnostic action. No further unrelated live-chat inspection, raw excerpts, fixture reuse or replay into this native conversation without that authorization. Prefer synthetic fixtures or verified related-work fixtures. Existing private audit artifacts remain diagnostic-only; previously authorized plan75 renderer fixtures are preserved and not repurposed as plan77 messaging/history fixtures.

Regression matrix: unrelated different-project peers; unrelated native sessions in the same cwd/process/room slot; targeted and broadcast delivery without related-work approval; late replies/snapshots/queued sends after native replacement; reconnect/resume and cache reopening. Negative cases must not contaminate native context, persisted/replayed transcript, another selected chat or outgoing queue. Positive cases cover verified native children and explicit approved sharing with provenance and bounded task/session scope. Report native-message admission, mobile routing/history and operator inspection results separately; one path passing is not evidence for another.

## Steps and acceptance

1. Identify each currently live PC conversation and its latest completed assistant text; do not confuse stale restored panes, retained children, working partial text, compaction summaries or earlier branches. Use bounded privacy-conscious fingerprints/snippets, never auth/secret/config key dumps. Installed remote-pi version0.7.0 equals local package version, but compare actual built code/API/event paths—not version labels alone.
2. Trace installed producer metadata/history/streaming and App consumer snapshots/live updates. Find a concrete mismatch in selected room and last message before proposing a fix. Cover reconnect, app resume, late snapshots, final message updates, compaction/branch/session switch and identical cwd. No invented freshness telemetry or tests that require an unchanged relay snapshot the real relay suppresses.
3. Specify a minimal producer/consumer correction and named owner if needed. The read-only audit and App voice-draft milestone are complete; the voice writer released ownership. No messaging/history/naming fixes are implemented or deployed and no implementation writer is currently assigned. Orchestrator owns this plan/integration and specifically authorized ADB observations; future native-message admission/producer fixes belong to pi-extension and selected-chat sync/cache/display/queue fixes to a separately assigned sole App writer. Partition contracts and integration verification; do not combine unrelated component implementation in one writer or globally publish a partial package. Any runtime package deployment/reload must preserve active jobs and require an explicit safe activation gate.
4. Use meaningful unique labels from existing authoritative Pi session names/room metadata or user-owned local aliases, retaining project/path/host/model context. Define short stable disambiguation only where needed. Do not assign guessed roles or silently rename active PC conversations. Name changes never rebind a cached transcript to another room. Avoid deleting cached rooms/pairing to make counts look right.
5. Regression/integration acceptance: two live agents in same cwd distinguishable, old offline room clearly different, latest completed PC message matches actual phone room after refresh/resume/live end, late responses cannot overwrite another selection, existing discovery/security behavior preserved. Report missing evidence honestly; no new dependency/download/relay/schema direction without explicit scope approval.
6. Parent observes only specifically authorized phone/PC conversations together, without submitting prompts, restarting agents, clearing data or re-pairing. Use synthetic/verified-related fixtures by default; broader live foreign-chat inspection requires explicit approval. Source tests and matching display names are not end-to-end freshness or relationship-admission proof.

## Audit milestone — 2026-10-11

Read-only audit is complete; report is private managed artifact `201472ec-ab2e-44ce-9a3c-79c0e77ef3ff/extension/77-session-freshness.md`. Current discovery found three report-bound PC conversations; four was historical. Installed producer0.7.0 has the same audited mechanisms as source, but whole loaded-module/build parity is not established; executable Pi SDK is1.1.0 versus the Extension dependency0.79.10. No runtime changes/tests/activation were performed by the audit.

Established source mechanisms:
- Producer history maps a process-local append buffer, not the SDK's current selected branch; startup/resume never hydrates it and tree/name changes are not observed. Use authoritative branch messages/markers, not compaction-generated LLM context, at safe lifecycle/request boundaries; SDK message_end precedes SessionManager persistence.
- App does not correlate latest history request/selection/live-update generations; a same-room older response can replace newer state. Connected foreground resume discovers peers but does not request chat history. Final-message recovery requires segment-aware reconciliation; merely emitting another AgentMessage preserves existing partial rows today.
- Desktop labels, routing mesh names and mobile-local aliases differ. `/remote-pi rename` rekeys routing and is not the display-only fix. Keep routing identity stable, distinguish remote display names from local overrides, and apply fresh metadata without overwriting aliases. No guessed roles or claims that a room suffix is a native Pi UUID.

Parent phone evidence remains private under `app/build/77-session-audit/`. A later selected ai-pc capture matches its latest persisted assistant tool-use text after accounting for this message's known Markdown bold rendering and terminal paragraph newline. This is rendered-accessibility matching, not raw received-payload fingerprint proof; the agent was still working. It does not prove all chats fresh, nor the originally reported exact mismatch. Earlier Home and later PC cutoffs differ; the two displayed dotfiles rows did not identify the subsequently discovered current dotfiles conversation. Do not infer a stale-registry defect or delete rooms from that moving comparison.

Next implementation ownership: Extension producer branch authority first; App snapshot/resume/completion and display policy after the sole voice-writer milestone. Source regressions must reproduce the missing-history and late-response mechanisms before correction. Runtime producer deployment/reload is a separate explicitly approved safe-activation gate, never automatic publication or restart.

## Admission preparation — current task

Following the user's request to continue unresolved issues, native workflow `04ceee7a-c1a2-4a59-a331-304fa10bd87b` assigns a bounded read-only Extension scout (Sol high) to session-scoped mesh admission and authoritative native-task lineage contracts. This is preparation for the existing isolation requirement, not authorization received from a different project's peer. No source/protocol/global-settings/runtime admission change or foreign transcript inspection is authorized by that scout handoff. Its report must identify missing provenance/approval contracts rather than inventing trust from names, role flags, ACKs or reply IDs. Parent will assign an exclusive implementation owner only after the smallest safe contract is concrete. The source history/identity defects above remain unimplemented.

## Latest preparation outcomes and user naming clarification

Admission scout completed: two independent content-ingress paths (mobile-before-native broadcast and re-only request/tool-result bypass), plus unstamped queued drains, require complete pre-sink scope authority. The smallest safe positive grant seam is absent today; next proposal is `plan/80-native-session-mesh-admission.md`. No admission implementation/activation is claimed.

User clarifies that Android's `dotfiles` label should track their manually named TUIOS `Pi · system` window and future window renames. Parent metadata inspection confirms the manual window name and cwd, plus TUIOS-reported native UUID; no chat/transcript content was inspected. This clarifies a display-precedence defect, not proof of phantom presence. `plan/81-tuios-mobile-display-name-sync.md` scopes that explicit override. Completed read-only naming scout proves Relay currently whitelists and discards unknown display fields, so a client/Extension-only tweak cannot meet the request. Its proposed narrow optional display/native-scope/epoch/revision field requires a producer–Relay–App contract and separately safe runtime activation. Canonical room names/IDs must not be renamed.

## New-context recovery queue — 2026-10-11

User explicitly asked to inspect Pi history and continue unfinished tasks. New root session `01a12c46-15f6-729a-96d3-9c64cf603870` recovered the previous coordinator `01a12afe-8bd6-765e-b724-0add4623a172` and read completed output artifacts; no prior workers remain active. No completed implementation was rerun. Plan79 UI-only code24 was verified and installed in place (phone gesture acceptance pending); plan78 installed presence hash still matches the reviewed patch. New exclusive App voice and Extension display producer runs are recorded in plan76/81.

Next ready steps on native completion: read saved report and final diff, resolve supervisor decisions within the approved local-patching scope, review exact native speech lifecycle/privacy seam and build code25+, and advance display transport through exclusive Relay then App component owners. App naming waits for voice source release. Parent owns installations/device acceptance; do not block native async progress or silently publish component drafts.

Authoritative SDK branch history and App selection/history-response/outgoing-queue epochs remain unresolved, not fixed by code24, presence or display names. Schedule Extension branch-history source after the current display producer releases; assign the matching App consumer only after capture/display ownership is free. Plan80 positive-sharing issuer/capability design remains a separate explicit contract gate: blanket permission to patch is not evidence of native lineage. None of these fixes has yet established all phone/PC conversations fresh at a common cutoff.

## Definition of Done

- [x] User requests clearer identities and actual latest-message matching; desktop duplicate label corrected only.
- [x] Read-only current PC identity/room/persisted-branch mapping and source-backed producer/consumer findings documented.
- [ ] Original reported selected-phone mismatch established at a shared cutoff, distinguishing final answers from working tool-use text.
- [ ] Minimal scoped fix/label policy with producer-consumer ownership and acceptance approved.
- [ ] Project/native-session isolation and explicit related-work admission pass separately for targeted peer messages, mobile history/cache/queued sends and authorized diagnostic inspection.
- [ ] Scoped host regressions/independent review pass against exact source.
- [ ] Actual phone-to-PC latest-message and duplicate-folder identity acceptance verified.

## Next plans

Plan76 tap/live dictation runs independently in App. Plan75 code23 is reviewed/installed; real output replay and the user's possibly different plain-color pane remain separate gates. Structured per-child live telemetry is not implied by this identity/freshness audit.
