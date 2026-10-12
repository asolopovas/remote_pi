# 82 — Readable Android fork release (code27)

## Context

Operator explicitly requested: “build everything and commit and push apk to releases in my fork give me link here to download”. This authorizes coordinator-controlled Git commit/push and GitHub release publication; prior no-commit/no-push limits continue for workers, not the coordinator. Never publish private signing keys or synthetic test APKs.

Verified fork/auth: `asolopovas/remote_pi`, authenticated login `asolopovas`, origin `git@github.com:asolopovas/remote_pi.git`; upstream remains untouched. Current branch `readable-android-fonts`, pre-integration HEAD `b865a73423573cbc92b6e0590765774418943752`. Keep branch history; no force push/main migration. Planned new tag `readable-android-code27`, verify absence before creation.

Plan81 exact reviewed two-file correction is integrated into original App: ChatPage SHA256 `b7a982c0b0163a2dde32f4ab4f67c4f129b6c53896a6040528ff4e86a3e8657b`; test `52582e76e8ef7242f8fd52bf2b64f7103695e1eb4c3838749329100701089691`. Actual App30 tests/analyzer/format passed;439 other protected/927 non-owned inputs preserved. Parent matched integrated441-input manifest `27061ff60e37cd5399fc4b8bab49ce411b48ce8210128d536bbcaae4461acedd`. Active LSP probe: one clean/one inconclusive timeout; not complete LSP acceptance. Original source/test ownership released.

## Expected structure

- New private production build stage; immutable `app/build/81-display/code27/code27.apk` and provenance/checksum evidence.
- Real App `lib/main.dart`, fork package `io.github.asolopovas.remotepi.readable`, activity `work.jacobmoura.remotepi.MainActivity`,1.2.0/code27,Android14+/ARM64, existing signer certificate `44dc580c702f2757fb296c989608dad2826e12e771cc7e4364d50bd587c8516a`.
- Root coordinator Git commit of intended source/tests/vendor/license/docs/plans only; ignore generated builds/caches/local keys/configs/logs.
- Fork GitHub release containing verified APK + checksum; download link returned to operator.
- Honest per-component build report and release limitations. Synthetic81 APKs, absent historical stages and private rasters are not production delivery.

## Steps and acceptance

1. **Integrated source:** match exact reviewed bytes and protected baseline; actual original-App focused30/CLI gates pass. Completed worker `7758df26-0fa5-40ff-ae0f-f8490def6509`, private evidence `/tmp/remote-pi-81-original-integration-5OHRAL`.
2. **Production APK:** builder `3854e0c4-8c21-489a-95dd-2de4c2aa8e0f` owns new build/staging only plus narrowly approved final `app/READABLE.md` release-status update. Fresh offline nonincremental main-target code27, correct package/signature/ELF/actual DEX local-factory gates and current-source→kernel→packaged AOT proof. No original product source changes/phone install. Docs changed after compiler snapshot must be disclosed separately as non-AOT metadata.
3. **Other components:** private-copy build worker `5275c569-f92f-412a-9914-9dac42d9dadf` produced fresh Relay release ELF hash `690b39f25ae5551f8eec4923e4e1cafab2acaa1f54a568b6368000b50ecd0d28`. rp-s3 blocked by uncached locked `mime_guess`;Cockpit lacks prepared package config/cached Git/native assets. Extension/Site initially blocked by no prepared node_modules. Retained continuation `ff1f3b9b-5f7f-4ab4-8fb0-dc84dff4b159` explicitly permits private OFFLINE frozen-lockfile dependency materialization from copied/read-only pnpm store, ignore scripts/network sandbox; no upgrades/downloads/global modifications. Report all successes/blockers, never all-built if partial. Relay not repeated.
   Offline Node continuation completed: Extension fails `ERR_PNPM_NO_OFFLINE_META` for `@aws-sdk/core`;Site for `@img/sharp-wasm32`. One sandboxed offline/frozen/scripts-disabled attempt each, no build ran or source/lock changes. pnpm policy metadata absent despite cached content; no policy bypass or download. Other four components remain BLOCKED; Relay PASS only among non-App. Full/delta reports consumed, no further retries. APK build proceeds separately; do not claim all-components success.
4. **Pre-publication review:** read complete build handoffs, verify source preservation/APK hashes/signature/current AOT and app docs. Keep existing intentional dirty work; inspect Git-visible additions for secrets/private keys/generated files; no `git add .` blind staging. Read workflow triggers before tag choice; publish only fork, not upstream.
5. **Commit/push:** after all original writers explicitly release, stage intended completed work, inspect staged diff/check/no secret artifacts, commit, push current branch to origin without force. Bind release tag to the exact committed source matching compiler closure; docs-only metadata may be later within same final commit if audited. No unreviewed source difference.
6. **Release:** create new fork release/tag after successful push/verification; upload APK + checksums (not keys/private evidence). Verify asset identity/size/hash and reachable GitHub download URL. Return direct link.

## Final artifact acceptance

Builder released BUILD/STAGING/DOCS ownership; no active original writers. Independent saved-artifact review `a3aa5b53-037d-4d5a-8c7d-7334f709d386` found no issues: publication OK with notes. Parent independently recomputed all441 original snapshot inputs, with only approved non-AOT `READABLE.md` delta, current exact ChatPage/test hashes, actual APK DEX/AOT hashes and `apksigner` certificate. APK **45,688,278 bytes**, SHA256 **ce5e6afb2091961a559bf1874b47336415c41fa5f29dd752929e459255eb146b**; checksum verifies. Package/min34/version27/ARM64 identity accepted. Parent scanned112 Git-visible changed/new files (1,691,223 bytes), no private-key/token/keystore/generated-binary findings, clean diff-check. Fork/tag absence checked; no upstream changes. Publication remains next step, not yet claimed. Staging additionally exposed128 whitespace diagnostics in the new vendor import, all matched retained upstream7.4.0 line bytes (including original blank EOF). First-party staged diff-check passes. Preserve exact approved vendor/compiler bytes instead of formatter churn; full vendor diff-check failure is disclosed, not silently called clean.

## Definition of Done

- [x] Operator Git/release authority and fork/auth verified.
- [x] Exact reviewed source integrated and actual-App focused gates accepted.
- [x] Fresh production code27 APK and independent delivery provenance accepted.
- [x] Requested component build outcomes truthfully recorded.
- [x] Intended source/tests/vendor/licenses/docs/plans committed and pushed to fork.
- [x] Exact verified APK/checksum published on new fork release.
- [x] Direct download link independently verified and ready for operator.

## Published delivery

Source commit **`e5c6edf777f682b69954973363e4565633fdd211`** pushed to origin `readable-android-fonts`; new immutable release tag **`readable-android-code27`** points to that exact commit. Parent checked432 Git-committed manifest entries;9 normal generated/local metadata/support entries are not Git files. No source mismatch, branch force push or upstream change.

Fork prerelease: <https://github.com/asolopovas/remote_pi/releases/tag/readable-android-code27>. APK: <https://github.com/asolopovas/remote_pi/releases/download/readable-android-code27/code27.apk>; checksum: <https://github.com/asolopovas/remote_pi/releases/download/readable-android-code27/code27.apk.sha256>. Both assets are uploaded, sizes45,688,278/77 bytes. GitHub server digest matches `ce5e6afb2091961a559bf1874b47336415c41fa5f29dd752929e459255eb146b`. Parent fetched both direct public HTTPS download links, independently hashed downloaded APK and compared downloaded checksum bytes; exact match. Not only an API/planned-URL claim.

Final coordinator documentation-only follow-up updates the App README publication line and this plan; release tag/source commit remain unchanged. Compiled source/native/vendor/fonts/config/tests/APK are unchanged. Builder's non-AOT README delta remains historical pre-publication evidence; final publication-status markdown is another explicitly non-AOT delta, not compiled bytes. No device installation or all-components build claim added.

## Limits and next plans

Release-mode APK uses existing local debug signer; this is a personal fork build, not official Play release. Production backup/account/screen-lock security stays intact. Phone disconnected; no contact/install/microphone/model/acoustic acceptance. Native history/admission, real TUIOS rename/reset and compatible producer/owned Relay rollout remain plans77/80/81; default community Relay is third-party and not deployed here. Cached-only build policy remains; missing non-App dependencies may prevent those builds without changing APK delivery. Do not invent lifecycle all-green: synthetic ordinary138/state witnesses accepted with master timing-driver failed, no exact closing-frame visual proof.
