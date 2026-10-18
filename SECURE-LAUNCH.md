# PIN-protected phone launcher

The mobile **+** action starts a fresh sandboxed agent in a locally registered project. It does not send an initial prompt/model turn.

## Host setup

Use this checkout's built extension and a compatible paired root host. New starts require Launcher API3; API2 remains supported for existing-child access/control. Linux launch needs bubblewrap and the credential/runtime/filesystem checks described in the [host contract](pi-extension/docs/secure-launcher.md).

Register only directories you authorize, from the local host:

```sh
remote-pi-launcher project-add 'My project' /absolute/project --allow /absolute/project
remote-pi-launcher project-list
# Optional local PIN setup/recovery; input is hidden and interactive:
remote-pi-launcher pin-setup
```

If the CLI is not on PATH, use `node /absolute/path/to/pi-extension/dist/bin/launcher.js` in its place. Never put a PIN in arguments, environment variables or chat. Existing/corrupt/unsafe PIN verifiers require local recovery; do not delete locks without proving no transaction is active.

## Phone workflow

1. Tap **+** and select a paired host when more than one exists.
2. Create the first 6–12 digit PIN on a supported host, or unlock an existing verifier. Existing PINs cannot be replaced remotely.
3. Select a registered project and confirm Start. Wait for real readiness/discovery.
4. Use **Check status** for uncertain results; a timeout does not prove no child was created. No mutation is automatically replayed. A new Start requires explicit duplicate-risk confirmation.
5. Use a confirmed Stop control for the exact owned agent. A requested acknowledgement is not proof of exit.

**Check access / Unlock launching host** recovers authority through the actual parent; legacy metadata requires explicit selection, never guessing. Grants are per Owner and launching session, expire after five minutes, and are not machine-wide. PINs are cleared on submission and lifecycle changes.

**Lock access** revokes control but leaves admitted children running. Launcher shutdown affects only that Owner's managed children, never the OS/relay or another Owner's jobs. Children survive phone disconnect, not their launching host's close/session replacement/reload. Offline **Remove from list** deletes local session metadata only; it is not Stop or history deletion.

## Limits and maintenance

Allowed roots are enforced, but sandboxed project code can read selected model credentials and access the network/local services. TLS is not E2E encryption. Start only trusted projects on trusted infrastructure.

New children require a compatible private runtime snapshot and validated configured provider/model; missing/unsupported defaults fail rather than silently selecting another model. See the [host contract](pi-extension/docs/secure-launcher.md) for API3 packaging and credential requirements, and [session control](pi-extension/docs/session-control.md) for stopping rules.

Update immutable runtimes only at idle-safe boundaries. Never reload an active job or delete a release that a session may still use. Automated fixtures do not establish real-phone, microphone, deployed-host or model-provider acceptance; validate these separately after deploying your own builds.
