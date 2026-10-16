# PIN/project launcher (App)

Use Home’s **Start agent** entry on the exact online paired launcher session.
Home’s header Refresh remains a discovery refresh; the launcher page’s Refresh
reads security, registered projects and your Owner’s managed agents.

Creation has one purpose: select an approved project and Start. Loading, missing
host setup and PIN unlock are separate states, not disabled creation forms.
Missing setup offers the local `remote-pi-launcher pin-setup` command; the PIN
field is editable only after the host actually has a verifier. Optional naming,
capacity counters and managed-agent headings are not part of creation. Existing
agents and access locking live under the page’s secondary menu.

The machine-side extension must support the launcher protocol and be configured
with a 6–12 digit PIN plus registered projects and directory allowlists. The
operator supplies the PIN; the App cannot set it or invent registered projects.
An unsupported host times out with an update/setup message. There is no legacy
freeform-directory launch fallback.

The obscured PIN is cleared on submission, background, target change and page
disposal. It is not saved or journaled. Current machine status, expiry, launcher
identity/epoch, paired host and room govern control. Cooldown and incorrect-PIN
errors come from the host. Disconnects/lease changes require selecting the host
again; expiry clears local authority. A project selection survives refresh only
if its full definition and host/launcher incarnation remain unchanged. During
refresh only a non-authoritative definition candidate is retained; controls stay
disabled until the complete security/project/agent reconciliation succeeds.
Neither PIN nor permission is restored from that candidate.

Launch starts a fresh sandboxed background agent without an initial prompt.
It survives phone disconnect but not launcher close/session replacement/reload.
Open its actual discovered online session from Home. Stop manages only the
requesting Owner’s managed records; the host remains the final owner authority.

**Lock access** in the secondary menu revokes local control; agents keep running.
**Started here** is a separate list of this launcher's app-created agents, with
confirmed per-agent Stop. It never
exposes OS/Relay shutdown or an aggregate stop action in the creation form.
Partial failures and unknown replies remain explicit, never automatically retried.

Session info separately offers **Stop agent** for the exact selected running
process. Its X only dismisses info. This control uses fresh short-lived one-use
host capabilities, exact channel/room/lifecycle guards, a confirmation, and no
PID/name/path targeting. Primary TUI Pi stops orderly using its SDK and may also
stop children it launched. App-launched child stops remain Owner/PIN-grant gated.
Unsupported primary RPC/print/JSON contexts are reported, not force-killed. A
`requested` acknowledgement is not proof of process exit; only `stopped` confirms
managed child exit. Control tokens/errors never become chat history.

Security and launch mutations are never automatically replayed. Unknown launch
attempts retain only IDs/type/incarnation, never payloads. Refresh is read-only.
After reliable security/project/agent reconciliation, a distinct confirmed Start
warns that the previous agent may still appear and another Start may duplicate
it. Only that explicit acknowledgement permits a new request ID. A later real
correlated result settles its own attempt, not a newer attempt. Errors must carry
locally verified authenticated outer host/room scope to settle management work,
even after reconnect or transport request-cache eviction. Legacy unscoped chat
errors cannot settle management requests.

The App-lifetime journal is bounded to 32 combined active/historical unknown
attempts across all targets. At capacity, new launches are blocked rather than
silently forgetting uncertain outcomes. Exact late replies free their own record;
complete authoritative reconciliation retires records from obsolete incarnations
of that same target. Empty history keys are removed.

Local automated tests cover wire shape, authenticated host/room scoping, locked
and setup gates, cooldown/errors, expiry and target invalidation, no replay,
unknown duplicate-risk confirmation, registered projects/allowlists, and Lock
versus shutdown. They do not prove machine sandbox enforcement, actual process
lifetime, Owner isolation or phone-to-host deployment. Those require integration
verification against the separately implemented host and operator-provided PIN.
