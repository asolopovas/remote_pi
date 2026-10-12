# 85 — Mobile Settings: session cleanup

## Context

The user requests a mobile Settings option to clean up old/obsolete Remote Pi sessions. Current Settings offers Relay, Display and Pairings, but no session cleanup. Home combines persisted room discovery with the local session index; clearing only one source would leave obsolete tiles or recreate them after restart.

**Status: approved for implementation; blocked on App worker availability.** The user explicitly chose both obsolete-session list removal and deletion of those sessions' phone-local chat history, then authorized an ADB app update and committing/pushing all changes. Root remains planning-only; implementation and build belong to `app/`. At handoff, no mesh peers or Cockpit/cmux executable are available.

## Proposed scope

Add **Settings → Sessions → Clean up old sessions**. This is an explicit, manual, phone-local operation, not pairing revocation, remote process termination or deletion of desktop session files. No automatic deletion in this first version.

Choices: inactive sessions older than 7 days, older than 30 days (default), or all confirmed inactive sessions. Show the eligible count and require confirmation. Cleanup removes eligible sessions from the mobile list AND deletes their phone-local chat history. Confirmation must explicitly warn that local history deletion cannot be undone; desktop history remains unchanged.

Preserve live, working, currently selected sessions and sessions with pending outgoing work. Relay disconnection/unknown presence is not proof that a session is obsolete. Do not infer eligibility from session display names, cwd or the local index's idle flag alone.

Keep pairings, owner/connection keys, relay configuration, nicknames and display preferences unchanged. A session genuinely announced live again may reappear normally; old restored caches alone must not resurrect cleaned tiles.

## Expected structure

- Settings UI and ViewModel using the existing phone route/tablet sheet and project state-management conventions.
- One app-owned cleanup service/write boundary coordinating cached room metadata, session index and local message storage.
- Focused policy/storage/widget tests. No relay/extension protocol change unless app-only feasibility proves insufficient and a separate decision is approved.

Relevant existing surfaces:

- `app/lib/ui/settings/settings_page.dart`
- `app/lib/ui/settings/viewmodels/settings_viewmodel.dart`
- `app/lib/data/transport/connection_manager.dart` — canonical cached rooms and live room IDs.
- `app/lib/data/local/boxes.dart`
- `app/lib/data/local/records/session_index_record.dart`
- `app/lib/data/repositories/home_read_repository.dart`

## Steps and acceptance criteria

1. **Resolve eligibility.** Scope is approved: remove obsolete tiles and their phone-local history. Trace persisted room caches, authoritative presence freshness, selected session, pending messages and index/message writers. Document how an age cutoff is computed; missing/invalid timestamps are not silently treated as ancient. If current contracts cannot prove inactivity safely, report the gap instead of treating offline as dead.
2. **Implement coordinated cleanup.** Preview eligible session identities keyed by peer + room. Revalidate eligibility at execution, including a room becoming live after preview. Coordinate with incoming sync and open message watchers; do not mutate read-only repositories. Removal must persist across restart and leave unrelated state untouched. A failure must report actual results, not unconditional success.
3. **Add Settings flow.** Scope chooser, eligible count, explicit confirmation, cancel, empty state, running state, duplicate-submit prevention and success/failure feedback. Copy must state this affects only the phone and does not delete PC sessions or unpair devices.
4. **Verify in the App workspace.** Unit tests for cutoffs, null dates, offline/unknown safety, live/working/selected/pending protections and preview races. Storage tests for restart persistence, stale-cache replay, real live rediscovery, partial failure and preservation of pairings/preferences. Widget tests cover cancel, zero candidates and success/error on phone and embedded Settings. Run focused tests and analysis from `app/`; report evidence. The user has authorized building and installing the updated app via ADB. Preserve the installed package/activity/signer and app data; use a greater installed versionCode and `adb install -r`, never uninstall or clear data. Explicitly target the connected physical Samsung device (discover current serial; do not install to the emulator by accident). Verify the new Settings action on that device without executing irreversible session cleanup as part of verification. Commit/push is authorized and remains the root orchestrator's responsibility after worker acceptance.

## Definition of Done

- [x] User confirms cleanup scope and local-history behavior: both mobile list removal and phone-local history deletion.
- [ ] Settings exposes a clear, confirmed bulk-cleanup operation.
- [ ] Live/working/selected/pending and unknown-presence sessions are protected.
- [ ] Cleaned stale tiles do not return from persisted cache on restart; their phone-local history is deleted.
- [ ] Pairing/security/preferences and desktop session files are unchanged.
- [ ] Focused tests and analysis pass; result lists files changed and limitations.

## Next plans

Optional automatic retention policy or individual-session cleanup, only after explicit product approval. Distribution/device install follows the established App release workflow separately.
