# 78 — Count primary Pi agents, not automatic child relay rooms

## Context

User explicitly requests finishing the repeated four-active-agents versus six-on-phone defect. Current metadata-only evidence: TUIOS reports four terminal Pi conversations (ai-pc, remote-pi, mbot, dotfiles); phone code23 Home shows Online6. Two extra rows are mbot managed workers `continue#2` and `continue#3`. Socket/process ownership correlates parent versus background runners without reading their transcripts. Evidence is private under `app/build/77-presence/`. Native pi-subagents runner sets `PI_SUBAGENT_CHILD=1` before child extensions load. Extension session_start automatically invokes root connection for configured children and root automatically starts the relay, exposing their local suffix names as primary mobile sessions.

This is distinct from plan74 missing-registration/heartbeat recovery and plan77 transcript isolation. Do not hide numeric excess, filter by names/suffixes/cwd or label a truly registered worker a dead process. The fix must prevent unintended child mobile exposure while preserving explicitly started top-level/headless sessions and related local agent communication.

## Expected structure

Single Extension writer. Parent owns plans, package integration and real-phone verification. No App source/build/APK changes: preserve plan75/code23 and blocked plan76 voice draft. Use the runner's explicit child-host marker to suppress only AUTOMATIC mobile relay start for managed children. Retain local mesh/locks and manual relay opt-in, ordinary interactive roots, explicit supervised daemons, configured relay-off, print-mode guard and lifecycle generations/reconnect cleanup. No new dependency, protocol/relay/server/global-settings change, transcript inspection, process killing or agent restart.

## Steps and acceptance

1. Regression first: managed child with inherited auto_start_relay=true joins its local mesh but does not open mobile Relay; ordinary parent/explicit daemon still auto-connect, and explicit manual child relay start remains intentional. Test reused-module session replacement and delayed startup authority, print/config-disabled behavior, no name-based filtering.
2. Apply smallest source correction and focused tests/docs in pi-extension only. Validate with already available toolchain/cached dependencies (no install/download); record any coverage gap, not a fictional test pass. Preserve sender/room authority and related-work isolation; no broader history/naming changes.
3. Review the exact presence diff and build/output provenance. Installed package/shared binary ownership is separate; coordinate with the dotfiles owner. Parent may apply a backed-up presence-only runtime artifact for this direct user repair, not publish the whole package or another task's unfinished changes. Do not overwrite active jobs or send /reload while busy; safe idle-only activation/no process restart and retain rollback.
4. Parent observe Home Online4 for the four actual primary roots at a shared metadata cutoff. Offline cached rooms/pairing/settings remain. Verify prevention using a bounded synthetic/related native child, without requesting unrelated agents create work. No foreign chat prompts/transcripts as fixtures. Parent's fix child must not be mistaken for an interactive root. A naturally returned count after old workers exit is NOT proof of prevention.

## Live progress and tool incident

Metadata-only phone observations fluctuated Online6→7 while background work/room registrations changed. A Home→foreground resume discovery refresh on installed code23 then produced **Online4 / Offline9 / All13**, containing exactly ai-pc, remote-pi, mbot and current dotfiles. Evidence: `app/build/77-presence/resume.xml`. Old cached rooms and pairing were retained. This repairs the current display using existing code, not proof of future-child exclusion or a source/deployment acceptance; the prevention fix remains pending. No foreign chat was opened or inspected.

Worker source task `5186d1ae-00f3-4f12-946a-6a9bc3932c62` completed and released Extension source ownership. Its first launch was rejected before startup for an unsupported timeout option, then retried with timeoutMs1h. During preflight, pnpm exec unexpectedly installed264 dependencies despite the no-download constraint. User was notified; that path was stopped. Parent approved retaining evidence and removing only task-created local node_modules/restoring proven task-only source/lock changes, not shared-cache deletion. Continue using explicit preexisting cached tool binaries only, never fetched tools or pnpm wrappers. Source/App/installed package were untouched at the incident checkpoint. Final report must inventory remaining incidental package/cache mutations; do not claim the no-download boundary was met. Installed-package ownership coordination is pending, and no global deployment/reload has occurred.

## Parent review and native boundary check

Independent reviewer `301beb1a-ed55-4533-9384-4d6ac1c30425` returned **OK with notes**, no source issues. Retained validation: four pre-fix failures, eleven focused passes, 809 full-suite passes / 3 skips, TypeScript typecheck/build exit0. Cached Vitest5/Vite8.0.14 differs from the locked Vitest4/Vite8.0.16; the pnpm download incident remains a disclosed compliance exception, not erased by passing tests. Reviewed compiled delta is exactly the child-marker snapshot plus two automatic-start guards.

Parent rechecked installed `dist/index.js`: SHA256 `7bd0af24c7c8a6440e0b85858afa61273a802f84efb78a5bb0ffa3b18e8c5ff7`, identical to the private backup. Candidate SHA256 `211cb0d22db2efe9ac5a81839fef0d8248e1d93e38aefdb18b2ee8e812631583`; source `index.ts` SHA256 `67c978123362dbd79df74516d00f79cf042b50bdcafb4adf6d5fe637afd43305`. Candidate diff saved at `app/build/77-presence/installed-candidate.diff`. Reviewer approves backed-up index-only activation, not whole-dist replacement. Keeping the installed map leaves diagnostic mappings stale after the insertion; map replacement requires separate parity/ownership proof.

Parent additionally constructed an isolated, in-memory native SDK1.1.0 session with the real compiled factory and `PI_SUBAGENT_CHILD=1`, inherited automatic Relay enabled, private temporary workspace/home and a loopback Relay connection trap. The factory joined local mesh, retained its lock, remained Relay-idle and made zero Relay connections. No model prompt, production Relay traffic, global package/config write or foreign transcript was involved. Explicit synthetic cleanup removed its mesh node and the process exited0. Evidence: `app/build/77-presence/native-sdk-probe.log` and the retained probe script. This establishes the SDK/marker boundary, **not** installed activation or actual phone prevention. The previously contacted package owner subsequently confirmed no competing installed-package writes/workers and retained this coordinator's package ownership. Following the user's instruction to continue outstanding issues, parent rechecked unchanged baseline/source/candidate/map hashes and atomically replaced **only installed index.js**, preserving mode775 and the original map. Evidence: `app/build/77-presence/activation.json`. No process restart, root reload, global settings change or whole-dist publication occurred. Existing roots keep their loaded modules; future children load the reviewed guard.

An additional bounded SDK probe imported the **actual installed** factory, not a temporary substituted package. It waited for the automatic-root final status notification before checking native mesh/lock retention, Relay-idle and zero trap connections; exit0, zero model prompts/global writes. Evidence temporarily retained at `/tmp/78-activated-presence-probe/probe.mjs` and `native-sdk-installed.log` (copy into durable evidence after App ownership release). Synthetic cleanup passed. This is installed SDK-boundary validation, not actual phone prevention. A related native workflow `04ceee7a-c1a2-4a59-a331-304fa10bd87b` now runs the App accordion writer and read-only Extension admission-contract scout; use metadata-only correlation for later presence acceptance, without inspecting foreign chats.

## Definition of Done

- [x] User reasserts defect; actual Home6 and terminal4 metadata discrepancy captured and child registration cause identified.
- [x] Managed-child auto-relay regression reproduced and corrected; parent/mesh/manual/daemon behavior retained.
- [x] Exact source and installed candidate reviewed/validated with rollback evidence.
- [ ] Safe activation plus actual phone4 and related-child non-inflation verified; pairing/offline cache preserved.

## Next plans

Plan77 native-session/history admission remains separately scoped and unimplemented. Plan76 local-only speech-library approval remains pending; neither blocks this Extension-only count repair.
