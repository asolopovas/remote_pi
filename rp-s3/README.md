# Download server

Small Rust/axum HTTP server for release artifacts and manifests. Maintainer and author of contributions: **Andrius Solopovas**. Its existing `LicenseRef-proprietary` metadata is unchanged.

## Run

Run from this directory with Rust/Cargo:

```sh
cargo build --release
DATA_DIR=./data PORT=8080 cargo run
curl -fsS http://localhost:8080/healthz
cargo test
```

| Variable | Default | Purpose |
|---|---|---|
| `DATA_DIR` | `/data` | Root served under `/downloads` |
| `PORT` | `8080` | HTTP listen port |
| `UPLOAD_TOKEN` | unset | Enables Bearer-authenticated manifest uploads; unset/blank disables the route |
| `RUST_LOG` | `rp_s3=info,tower_http=info` | Logging filter |

## Routes and operation

- `GET /healthz`: health check.
- `GET /downloads/<product>/<file>`: files below `DATA_DIR/<product>/`, without directory listing.
- `PUT /upload/<product>/<file>`: manifest write via temporary file and rename, authenticated with `Authorization: Bearer <token>`. Only `latest.json`, `SHA256SUMS` and `*.xml` are accepted; binary releases belong in release assets.

Artifact extensions `.dmg`, `.exe`, `.deb`, `.rpm` and `.zip` use attachment/one-year immutable cache headers; other files use a five-minute cache. Successful download responses permit CORS reads from any origin. Serialize uploads to the same target: the temporary filename is shared, so concurrent writes are not coordinated. Publish immutable artifacts at versioned paths and back up the data volume.

Terminate TLS at a reverse proxy; do not expose upload tokens over HTTP. Configure a private token through your deployment secret store. Review `docker-compose.yml` volume paths and image destinations and `push-docker.sh` before using them: their upstream defaults are not this repository's deployment.
