# Remote Pi

Control a local [Pi coding agent](https://github.com/earendil-works/pi) from a phone, connect agents through a local/cross-PC mesh, or use the Cockpit terminal workspace.

Maintainer and author of contributions: **Andrius Solopovas**.
Derived from [Remote Pi by Jacob Moura](https://github.com/jacobaraujo7/remote_pi).

## Project map

Each guide owns its project's prerequisites, build/run commands, configuration and maintenance. Run commands from the directory named in that guide.

| Project | Location and guide | Responsibility |
|---|---|---|
| Host extension | [pi-extension/](pi-extension/README.md) | Pi integration, local broker, relay client and managed agents |
| Relay | [relay/](relay/README.md) | WebSocket routing, presence and signed membership storage |
| Mobile client | [app/](app/README.md) | Android/iOS pairing, chat and remote controls |
| Cockpit | [cockpit/](cockpit/README.md) | Terminal workspace, CLI and [shared packages/headless server](cockpit/README.md#package-map) |
| Website | [site/](site/README.md) | Product pages, tutorials, download links and installer delivery |
| Download server | [rp-s3/](rp-s3/README.md) | Release files and update-manifest hosting |

## How the projects connect

- **Phone control:** the [mobile client](app/README.md#connect-and-use) and [host extension](pi-extension/README.md#build-and-install-this-source) connect through the same [relay](relay/README.md#self-host-with-docker). Start with those guides, then pair the client. Local-only agent messaging does not require the relay.
- **Terminal workspaces:** [Cockpit](cockpit/README.md#remote-host) connects to its headless server over SSH. This is separate from the mobile/extension relay protocol; running Pi inside a Cockpit terminal is optional.
- **Distribution:** [local release packaging](cockpit/packaging/README.md) and [mobile build instructions](app/README.md#build-and-run) produce artifacts. The [website](site/README.md#integrations) links to release downloads and [download-server manifests](rp-s3/README.md#integrations); neither service is required for a local source build.
- **Shared presentation:** [branding/](branding/README.md) holds source artwork used by the clients, website and package metadata.

## Documentation ownership

Use these canonical references instead of copying their details into another project:

| Topic | Reference |
|---|---|
| Mobile/extension/relay wire format, identity, pairing and trust model | [PROTOCOL.md](PROTOCOL.md) |
| Phone project-launch workflow | [SECURE-LAUNCH.md](SECURE-LAUNCH.md) |
| Host launch configuration, authority and sandbox contract | [Launcher contract](pi-extension/docs/secure-launcher.md) |
| Exact-session stop and display metadata | [Session controls](pi-extension/docs/session-control.md), [room display](pi-extension/docs/room-display-endpoint.md) |
| Agent messaging and asynchronous replies | [Agent-network skill](pi-extension/skills/agent-network/SKILL.md) |
| Cockpit features, transports and native internals | [Cockpit reference index](cockpit/README.md#reference-and-maintenance) |
| Secret handling, vulnerability reporting and publication gates | [SECURITY.md](SECURITY.md) |
| Development scope and documentation rules | [Contributor instructions](CLAUDE.md) |

## Maintenance

Build this checkout using the linked project guides; upstream npm packages, installers and existing update URLs are not releases of this independent repository. There are no GitHub workflows; testing, building and publishing are local/manual. Review publication destinations and signing before releasing; follow the [security gates](SECURITY.md#before-publication-or-deployment).

Check documentation navigation after changes:

```sh
python3 scripts/check-docs.py
python3 scripts/check-docs.py --self-test
```

Each guide must link back to its project or this index. Keep durable facts in one owning document; use relative Markdown links for cross-project discovery. Record manual releases in the [Cockpit changelog](cockpit/CHANGELOG.md).

## License

[MIT](LICENSE). Package and third-party licenses remain in their respective directories.
The [download-server manifest](rp-s3/Cargo.toml) also declares `LicenseRef-proprietary`; that existing license discrepancy is unresolved, not relicensed by this cleanup.
