# Exact-session stop (inner opaque-envelope protocol)

Authenticated, currently paired Owners can query their assigned room:

```json
{"type":"session_control_status","id":"query","room_id":"assigned-room"}
{"type":"session_control_status_result","in_reply_to":"query","room_id":"assigned-room","can_stop":true,"token":"fresh-random-confirmation","reason":"Stopping this Pi also closes its managed children."}
{"type":"session_stop","id":"confirmation","room_id":"assigned-room","token":"fresh-random-confirmation"}
{"type":"session_stop_result","in_reply_to":"confirmation","room_id":"assigned-room","state":"requested"}
```

`can_stop:false` never includes a token. Locked managed rooms return the reason
`Unlock the launching host first.` Rejections use correlated `error` messages.
Requests/results reject unknown fields; IDs, rooms and tokens are nonempty,
control-free strings of at most 128 characters. No PID/path/environment/command
surface is exposed. These controls never enter model input or history.

Tokens are random 256-bit, valid for 30 seconds, single-use, and bounded to 256
pending capabilities. They capture Owner, channel/room and lifecycle authority.
Primary TUI sessions additionally capture the native SDK session ID and context;
replacement, reload, reconnect and revocation invalidate pending authority. Stop
acknowledges `requested` **before** guarded SDK `ctx.abort(); ctx.shutdown()`.
Root shutdown uses existing session cleanup, including its managed children.

Managed-room authority is the immutable owned launch record + actual child
object + unique per-launch room (not a transcript branch within that process).
It additionally requires current launcher grant/epoch and pairing. The parent
uses its existing bounded owned-child stop primitive; `stopped` is emitted only
after confirmed child exit and a final authorization check. Child exit cleanup
is deferred only during that stop so a best-effort response can be attempted.
No child-controlled target selection or new child IPC controls are added.

Delivery is best effort: an acknowledgement may be lost, or `requested` may be
followed by an SDK failure. Treat a timeout/disconnect as **unknown**, never
silently retry a consumed confirmation. A `requested` response is not proof of
exit; observe the process/room ending. No automatic retry is implemented.

Primary RPC/print/JSON sessions report unsupported. In cached Pi **0.79.10**,
RPC `ctx.shutdown()` merely sets a flag checked on the next RPC input; it cannot
reliably stop an idle externally controlled RPC process. The isolated real-Pi
smoke documents that SDK limitation with one synthetic subsequent `get_state`
command; production does not send such a command or substitute a transport.
Managed RPC children still use the parent's existing owned-process stop path.
