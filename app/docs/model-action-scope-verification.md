# Plan 105 P1 — pre-discovery action scope correction

## Change and evidence

ActionsRepository now captures ConnectionManager's room revision even when room
metadata is absent. That lease covers only the captured unknown state: the first
announcement, replacement, room end/cache cleanup or socket reset revokes it.
Room-revision cleanup cannot revive an unknown lease because socket cleanup also
advances the captured socket generation. No fresh guard is adopted by an old VM.
Dispatch also checks its captured scope before sending.

The pre-discovery regression uses an explicitly bound `main` PeerRecord. Without
that binding, legacy discovery changes the selection epoch and masks the bug.
Against the original code the bound regression failed: the old pending catalogue
successfully returned stale models instead of ActionFailure
(`/tmp/105-p1-red.log`). The corrected suite covers a VM and pending list created
before announcement, announcement/replacement/ABA, late catalogue rejection,
metadata deletion without sampling the old guard, no old-VM mutation, fresh-VM
reconciliation/selection, and visible picker failure without Retry renewal.

The loopback WebSocket tests exercise production ActionsRepository →
PlainPeerChannel → WsTransport. Calling ModelSet then changing rooms without an
intervening await sends exactly one mutation to the original room. Room changes,
timeout and subsequent selection ABA do not replay it. This does **not** prove
that arbitrary custom deferred transports can retract an already requested send;
a timeout cannot undo delivery or prove the model did not change.

Two older repository error/timeout assertions now await their result before
connection disposal. The first focused run exposed the error-assertion race
(463 passed, 1 failed); final gates below include the correction.

## Final offline gates

Cwd: `/home/andrius/src/remote-pi/app`. All Dart/Flutter commands ran under:

```sh
/home/andrius/.pi/durable-subagents/bin/pi-durable-subagents hold machine -- bash -c '…'
```

Commands inside the final lease, in order:

```sh
dart format lib/data/actions/actions_repository.dart lib/data/transport/connection_manager.dart test/data/actions/actions_repository_test.dart test/data/actions/model_action_scope_test.dart test/transport/ws_transport_discovery_recovery_test.dart
find lib test -type f -print0 | sort -z | xargs -0 sha256sum > /tmp/105-p1-evidence/source-manifest-final.sha256
sha256sum pubspec.yaml pubspec.lock analysis_options.yaml >> /tmp/105-p1-evidence/source-manifest-final.sha256
sha256sum /tmp/105-p1-evidence/source-manifest-final.sha256
flutter analyze --no-pub lib/data/actions/actions_repository.dart lib/data/transport/connection_manager.dart test/data/actions/actions_repository_test.dart test/data/actions/model_action_scope_test.dart test/transport/ws_transport_discovery_recovery_test.dart
flutter test --no-pub --concurrency=1 test/data/actions test/ui/chat/quick_actions test/transport test/agents test/ui/home
flutter test --no-pub --concurrency=1
sha256sum --check /tmp/105-p1-evidence/source-manifest-final.sha256
```

- Format: 5 files, 0 changed. Changed-file analyzer: no issues.
- Active LSP probe: 5 files, 0 diagnostics; no unavailable/inconclusive files.
- Focused: **464 passed**. Full serial offline: **1,092 passed**.
- Manifest: **286/286 hashes matched** after gates. Captured before analyzer/tests.
- Manifest SHA-256:
  `e1a231653a1a4931af92f00957aab25478006d6c87d24d644687a4459ca77469`.
- Logs: `/tmp/105-p1-evidence/{format-final,analyze-final,focused-final,full-serial-final,manifest-check-final,gates-final}.log`;
  active probe summary: `/tmp/105-p1-evidence/lsp-final.txt`.
- An earlier unscoped `flutter analyze --no-pub` was stopped after approximately
  two minutes; it is not claimed as a clean whole-tree analysis. The final
  changed-file analyzer above completed cleanly.

## UX, limits and handoff

Discovery invalidates the existing VM permanently. Retry in the old picker does
not renew authority; a new VM is required (leave/re-enter the selected chat if
reopening the picker reuses its existing VM). The current “Reopen model picker”
error does not itself instantiate a new VM. This correction intentionally does
not refactor that lifecycle or fabricate production room metadata.

The machine lease is released. Host SDK refresh work is the next separately
owned dependency; no Node/host files, production Relay/provider/model turns,
credentials, builds/APKs, ADB, commits or root documents were touched here.
Physical Samsung/ADB remains disconnected per the supplied context; no physical
acceptance or new package is claimed. Future packaging must verify the captured
source hashes rather than infer provenance from mtimes, and capture its native
packaging inputs separately.
