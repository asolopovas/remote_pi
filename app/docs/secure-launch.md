# PIN/project launcher (App)

Use Home’s **Start agent** entry on the exact online paired launcher session.
Home’s header Refresh remains a discovery refresh; the launcher page’s Refresh
reads security, registered projects and your Owner’s managed agents.

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
if its full definition and host/launcher incarnation remain unchanged.

Launch starts a fresh sandboxed background agent without an initial prompt.
It survives phone disconnect but not launcher close/session replacement/reload.
Open its actual discovered online session from Home. Stop manages only the
requesting Owner’s managed records; the host remains the final owner authority.

**Lock** immediately revokes local control and asks the host to lock access;
agents keep running. Confirmed **Stop your managed agents and lock access**
asks the host to stop only this Owner’s managed agents and globally lock launcher
access. It does not shut down the OS, Relay or other Owners’ agents. Partial stop
failure is explicitly reported; lost replies do not imply host-side success.
Refresh status or inspect the machine before further action.

Security and launch mutations are never automatically replayed. Unknown launch
attempts retain only IDs/type/incarnation, never payloads. Refresh is read-only.
After reliable security/project/agent reconciliation, a distinct confirmed Start
warns that the previous agent may still appear and another Start may duplicate
it. Only that explicit acknowledgement permits a new request ID. A later real
correlated result settles its own attempt, not a newer attempt.

Local automated tests cover wire shape, authenticated host/room scoping, locked
and setup gates, cooldown/errors, expiry and target invalidation, no replay,
unknown duplicate-risk confirmation, registered projects/allowlists, and Lock
versus shutdown. They do not prove machine sandbox enforcement, actual process
lifetime, Owner isolation or phone-to-host deployment. Those require integration
verification against the separately implemented host and operator-provided PIN.
