# 103 — Phone agents inherit the configured host model

## Context

Operator reports a new phone-launched agent defaulting to GPT5.5 while the Linux
host default is GPT6.1Sol. Local read-only settings inspection confirms
`defaultProvider: openai-codex`, `defaultModel: gpt-6.1-sol`. Settings is the known
symlink to ~/.agents/pi/settings.json. No agent-directory models.json/models.jsonc
was found and no sol/provider-specific package declaration was identified; do not
assume this is a custom plugin rather than a newer built-in/catalog model.

Current sandbox uses the cached Pi0.79.10 runtime and copies only validated default
provider/model strings plus selected-provider private auth, not the host's full
model catalog/runtime. Earlier evidence already showed gpt-6.1-sol absent from that
cached catalog and SDK fallback to an available model. Diagnose exact registry/API
compatibility before deciding how to transfer/resolve the default safely.

## Expected structure

- Pi Durable scoped read-only diagnosis followed by bounded implementation/review.
  Preserve all uncommitted99–102 changes, one-machine picker and checkout cleanup.
- New agent must use the configured provider/model exactly when representable.
  Never silently substitute GPT5.5 or another available model when an explicit
  configured default cannot be resolved.
- Prefer a minimal validated selected-model definition from the actual host model
  registry or an appropriately compatible installed runtime, not copying the whole
  user config, arbitrary extension code, credential commands or account pools.
- Preserve existing model auth/sandbox/allowlist boundaries; no new credentials,
  plaintext logging, raw model/auth headers or unapproved endpoint/config changes.
- Distinguish configured default from a resumed session's model and from a parent
  session's temporary manual choice. Preserve intended provider/model semantics,
  not just a renamed UI label.
- Do not interrupt or silently change existing running agents/model turns. Host
  reload kills its managed children: inventory ownership before any activation.
  If a safe activation path is unavailable, report the exact lifecycle constraint.

## Approved implementation direction

Durable investigation01M560HYD6ZWA0CREPF1D4WF01 established authoritative bundled
Sol data in installed Pi/PiAI1.3.0, introduced0.99.1. Model is built-in Codex with
API openai-codex-responses,500k context and new capability/thinking handling absent
from cached0.79.10. Do NOT merely copy/rename a model descriptor into that old API
adapter and claim parity. Installed version does not prove the versions currently
loaded in existing long-running roots.

Use a validated current installed Pi CLI/runtime supporting the selected builtin
model and its complete trusted dependency/assets closure, with explicit readonly
sandbox allowances or a reproducible private immutable runtime snapshot. No package
downloads or wholesale host HOME/globalconfig/account-pool mounting. Do not mount
unrelated global package/config trees as an expedient: retain only runtime closure
or a validated self-contained snapshot. Remote callers cannot select runtime paths,
commands or flags. Keep extension/auth/filesystem boundaries intact.

Pass explicit configured provider/model and verify actual get_state provider/id/API
before ANY managed room publication; both event orderings must be covered. Missing,
unsupported or mismatched explicit defaults fail without fallback success. Resolve
configured defaults, not a temporary model on the parent session.

Emit launcher API3 for exact-default/readiness guarantees. Fresh App starts must
avoid older endpoints that can silently substitute a model; pin/recheck the same
compatible endpoint before PIN/Start, retaining one-machine UX. Access recovery and
control of existing API2 children remains supported; never replace their actual
parent with another root just because that root has API3. A clear compatibility
error is preferable to an old-session default substitution.

Live scope at investigation: managed mbot child2421411 belongs to coordinator876568.
Do not reload that root. The other msg-bridge root2016392 was working; no free idle
childless root was established. Safe activation must be rechecked at delivery; source
success alone cannot close this runtime constraint. No stopping/reloading a user job
to claim completion, no new daemon or extra infrastructure agent.

## Steps and acceptance

1. Establish where host6.1Sol is registered, model/API compatibility, child fallback
   path, current loaded runtime differences and managed-child ownership (metadata
   only; no credential reads/provider requests/phone PIN capture).
2. Add a regression reproducing explicit6.1Sol→5.5 fallback; correct minimal model
   bootstrap and pin/verify selected provider/model before reporting launch ready.
   Missing/unsupported model gives an actionable error, not fallback success.
3. Validate real sandbox/Pi get_state and parent-managed readiness against synthetic
   credentials/loopback; exact model ID/provider preserved, no paid model turn.
   Cover standard defaults, absent defaults, custom/unsupported metadata, malformed
   config, settings symlink, auth limits, races and cleanup.
4. Independent review, compiler/affected suites and current-source runtime/App builds
   only as required. Deliver safely without reloading a host with user children.
5. Verify actual phone new-agent model when private authorization/runtime readiness
   permits; don't change an ongoing user's agent to manufacture acceptance.

## Definition of Done

- [x] Exact fallback cause and model source established.
- [x] New starts preserve configured model, or fail explicitly without substitution.
- [x] Security/compatibility/readiness regressions and independent review pass.
- [ ] Safe deployment and actual model-selection evidence/limits recorded.

## Delivery — 2026-10-18

Source/review gates passed. The complete private installed-layout release was
independently compiled and tested:119 affected,1094 full passes/3 skips, real
network-isolated Pi1.3.0 exact Sol state (provider/id/API,500k context/128k output)
and signed parent-only loopback/control/owned-fixture Stop. No paid model turn.
Both readiness event orderings are gated before publication; unsupported explicit
defaults fail closed. App new starts require API3; API2 existing-agent controls and
actual-parent recovery remain supported.

Published **for future loads only**:
`~/.pi/agent/npm/node_modules/remote-pi/.releases/exact-model-a6d95d8ecba89c34`.
All26095 files/765 internal symlinks were reverified on copy; readonly runtime
snapshot manifest `cf6860bb0dd14c73bd0f4129077f83f8c52927f68861b12b12fcb32389e2b3ad`.
Root manifest `08f768a4283d8a57be0d9d398f7525f73fa9d790cc8cc802652260f42a1f5fe8`;
publication backup/receipt `~/.pi/remote/backups/remote-pi-host-plan103-20261018-011300/`.
Existing immutable releases retained; no existing root reloaded by this publication.

Samsung code55 installed in place and pulled back byte-identical:
`app/build/releases/code55/accepted/code55.apk`, SHA256
`84630429f33566576e9e84767a96cb01b4531aa8088ace1e023f035149860562`.
Same signer, UID and original install time preserved. Fresh independent App415
focused+49 matrix passes, analyzer clean; current full1061 retained, not relabelled
as an independent packaging rerun.648 App/extension sources remained unchanged.

At initial delivery no safe activation slot existed: coordinator876568 still owned
mbot2421411, while msg-bridge2812854 had background work despite native subagents:0.
The passive monitor made no changes and failed closed on uninspectable transient
process metadata. A later fresh preflight, not that monitor result, established an
idle/ready msg-bridge with no scoped background executions or managed descendants.

Plan105 then reconciled modern async catalogue refresh, published complete immutable
B at `~/.pi/agent/npm/node_modules/remote-pi/.releases/model-actions-59c3ca45c8186da9`
and executed an extension-only reload on that idle root. B native imports and
unchanged PID/native session were observed. Main876568 and mbot2421411 retained
original process start ticks and ancestry; no user process Stop/restart/model switch.
Host B gates:294 focused,119 managed,1118 full passes/3 skips; snapshot remains Pi1.3.0.

**Owner-endpoint API3 and actual-phone new-model acceptance remain open.** Phone USB
and paired ADB mDNS are unavailable. Code56 is built, not installed (see plan105).
The existing GPT5.5 child is intentionally unchanged. Fixture/import evidence is not
claimed as a newly launched production-phone agent or a successful owner RPC.

## Next

Access lifetime remains unchanged pending the user's decision. No new machine
service, model login, global default rewrite or running-agent switch is implied.
