# Relay

Rust/axum WebSocket routing, presence and Owner-signed mesh membership storage. Maintainer and author of contributions: **Andrius Solopovas**.

## Build and run

Use a Rust toolchain supporting edition 2024. Run from this directory:

```sh
cargo build --release
RUST_LOG=info ./target/release/relay
cargo test
cargo clippy -- -D warnings
cargo fmt --check
```

| Variable | Default | Purpose |
|---|---|---|
| `REMOTEPI_RELAY_PORT` | `3000` | HTTP/WebSocket port on `0.0.0.0` |
| `REMOTEPI_MESH_DB_PATH` | `data/mesh.db` | Signed membership SQLite database |
| `RELAY_MAX_CT_MIB` | `4` | Estimated decoded payload limit in MiB; invalid/zero falls back to default |
| `RUST_LOG` | unset | Tracing filter, e.g. `info` |

Routes: `GET /` upgrades to WebSocket; `GET /health` checks health; `GET`/`POST /mesh/<owner_pk_hash>` reads/writes signed membership versions.

## Self-host with Docker

Build this source rather than assuming a public registry image contains it:

```sh
docker build -t remote-pi-relay .
docker run -d --name remote-pi-relay \
  -p 127.0.0.1:3000:3000 \
  -v remote-pi-data:/data \
  -e RUST_LOG=info --restart unless-stopped \
  remote-pi-relay
curl -fsS http://127.0.0.1:3000/health
```

The Dockerfile sets the database path to `/data/mesh.db`. Keep `/data` persistent and backed up. Put the loopback-bound port behind a TLS reverse proxy, for example Caddy:

```text
relay.example.com {
    reverse_proxy 127.0.0.1:3000
}
```

Configure **both clients** using `https://relay.example.com`, not `wss://`; the transport derives the WebSocket URL. In Pi, run `/remote-pi set-relay https://relay.example.com`, inspect `/remote-pi config`, then reconnect at an idle-safe boundary. A VPN can additionally restrict reachability.

The built-in third-party community relay is `https://relay-rp1.jacobmoura.work`; it is not operated by this repository. For the existing IP-only deployment's certificate renewal, checks, backups and rollback, see [deploy/fn/README.md](deploy/fn/README.md). Its dated deployment evidence is not a claim of current live verification.

## Trust and maintenance

TLS protects transit, not E2E confidentiality. The relay operator controls the TLS endpoint, executable and storage. Ed25519 challenge-response proves possession of the connection key; endpoint pairing remains a separate responsibility.

The shipped relay does not decode outer App↔Pi `ct` bodies, log/persist message payloads, or store them in SQLite. Pi→Pi envelopes are parsed transiently for routing. A signed Owner blob permits a route when it directly lists both Pi keys; this does not prove that the Owner paired with or controls either Pi. Membership is not transitive between overlapping blobs.

SQLite stores only signed membership authorization metadata, using rollback-journal mode. POST versions must increase; bodies are capped at 500 KB. Positive authorization cache entries may delay revocation up to 60 seconds; negative sender misses last one second. Back up SQLite with an online backup or quiesced service, not an uncoordinated live file copy.

See [PROTOCOL.md](../PROTOCOL.md) for exact wire limits, errors and historical mixed-version compatibility. Upgrade clients and relay together during a maintenance window; do not infer current compatibility from old rollout plans.

[MIT license](../LICENSE).
