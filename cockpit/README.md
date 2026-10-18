# Cockpit

Flutter terminal workspace with files, Git/worktrees, databases and tasks. Remote workspaces use SSH and `cockpit-server`, not the Remote Pi relay. Maintainer and author of contributions: **Andrius Solopovas**.

## Develop

Use Flutter with Dart compatible with `pubspec.yaml` (`^3.12.0`); release CI pins Flutter 3.47.5. Native builds also need Rust/Cargo and Zig 0.16.0 where Ghostty is compiled, plus the platform's Flutter desktop toolchain. Git dependency overrides in `pubspec.yaml` are intentional pins; update them only with native-asset compatibility checks.

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d linux            # or macos/windows on that platform
```

Read [CLAUDE.md](CLAUDE.md) for feature boundaries, localization and terminal rules. The agent runs as a process in a terminal; the removed native RPC-agent UI is not a supported path.

## Remote host

On a matching Linux x86_64/arm64 build machine, create a bundle from this source:

```sh
./tool/build-server-zip.sh "$PWD/build/server-release"
```

Copy the resulting ZIP to the host, unpack it and run its `cockpit-server/install.sh`. Keep the app and server versions matched. The installer verifies its bundle, smoke-tests it, installs under `~/.cockpit/server` and links `~/.local/bin/cockpit-server`. Connect using the app's SSH host settings.

```sh
cockpit-server --version
cockpit-server service install     # optional systemd user service
cockpit-server service status
cockpit-server service uninstall
```

`install-server.sh` downloads prebuilt GitHub releases and defaults to the upstream repository. Use it only after publishing compatible releases of your own and setting `COCKPIT_REPO=owner/repository`. Review update/download destinations before distributing clients.

## Reference and maintenance

- [Packaging and signing](packaging/README.md); release CI requires the first version in [CHANGELOG.md](CHANGELOG.md) to match the release tag.
- [Remote protocol](docs/remote-protocol.md) and [Windows SSH setup](docs/windows-host-setup.md).
- [Tasks](docs/tasks-json.md), [layouts](docs/layout-ckp.md), [notebooks](docs/notebook.md), [themes](docs/theme-format.md) and [CLI skill](cli/text/skill.md).
- [Agent status hooks](docs/turn-status-hooks.md) and [terminal flow control](docs/terminal-output-flow-control.md).
- [Telemetry](docs/telemetry.md) and [Linux profiling](docs/linux-performance-profiling.md). Developer mode is off by default; telemetry is stored locally, not sent to a service.

Local workspace/database/SSH configuration belongs outside Git. Keep terminal, PTY, icon and bundled JavaScript licenses with distributions; the JavaScript notice files are packaged beside the assets.
