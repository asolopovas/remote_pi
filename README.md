# Remote Pi

Control a local [Pi coding agent](https://github.com/earendil-works/pi) from a phone, connect agents through a local/cross-PC mesh, or use the Cockpit terminal workspace.

Maintainer and author of contributions: **Andrius Solopovas**.
Derived from [Remote Pi by Jacob Moura](https://github.com/jacobaraujo7/remote_pi).

## Components

| Directory | Purpose | Setup and maintenance |
|---|---|---|
| `pi-extension/` | Node/TypeScript host extension, broker and managed agents | [Extension guide](pi-extension/README.md) |
| `relay/` | Rust WebSocket routing and signed mesh membership | [Relay guide](relay/README.md) |
| `app/` | Flutter Android/iOS client | [Mobile guide](app/README.md) |
| `cockpit/` | Flutter terminal workspace and SSH-connected server | [Cockpit guide](cockpit/README.md) |
| `site/` | Next.js website and legal pages | [Site guide](site/README.md) |
| `rp-s3/` | Rust download and release-manifest server | [Download server guide](rp-s3/README.md) |

Run each component's build and test commands from its own directory. The mobile client needs a host extension and relay; Cockpit remote workspaces instead use SSH and `cockpit-server`.

## Start from source

Requirements: Pi, Node 20+ and pnpm for the extension; Flutter and the platform SDK for the mobile client. Rust components require Cargo; relay uses edition 2024.

```sh
cd pi-extension
pnpm install --frozen-lockfile
pnpm typecheck
pnpm test
pnpm build
pi install .
```

In Pi, run `/remote-pi` to configure the directory, then `/remote-pi pair` to display a pairing QR code. Build/run the [mobile app](app/README.md) and scan it. Use the same relay URL on both sides. The npm package named `remote-pi` is not a release of this independent repository; use the local source above.

For local-only agent messaging, disable relay auto-start in setup. Discover addresses with `list_peers`, copy them exactly, and send with `agent_send`. A delivery ACK is not a content reply; replies arrive later with `re`. `agent_request` is deprecated.

## Configuration and security

- Relay URL precedence: `REMOTE_PI_RELAY`, then `~/.pi/remote/config.json`, then the built-in third-party community relay. Configure an owned relay with `/remote-pi set-relay https://your-relay.example`.
- The app has its own relay setting. HTTP(S) is the configuration form; WebSocket schemes are derived by the transport. Use HTTPS outside isolated development.
- TLS protects transit, **not end-to-end confidentiality**. The relay operator remains trusted. Connection-key authentication does not prove pairing or ownership of every routed Pi.
- See [PROTOCOL.md](PROTOCOL.md) for wire contracts and trust boundaries, and [SECURE-LAUNCH.md](SECURE-LAUNCH.md) for PIN-protected phone launches.
- Existing installers, update URLs, site content and release workflows may still target upstream infrastructure. They are not deployments or releases maintained by this repository; review destinations, signing and secrets before enabling publication.

## Maintenance

Use the checks in each component guide before committing. Keep credentials, signing keys, local `.pi/`, `.claude/` and `.cockpit/` state, logs and build outputs out of Git. Lockfiles and required generated source/resources remain versioned where builds depend on them. Release automation consumes [cockpit/CHANGELOG.md](cockpit/CHANGELOG.md).

## License

[MIT](LICENSE). Package and third-party licenses remain in their respective directories.
`rp-s3/Cargo.toml` also declares `LicenseRef-proprietary`; that existing license discrepancy is unresolved, not relicensed by this cleanup.
