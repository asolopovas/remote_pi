# 92 — Secure IP-only relay on fn

## Context

The operator requested a Docker deployment of Remote Pi Relay on SSH alias `fn`, accepted an IP-only endpoint, requested the most secure compatible method backed by official documentation, and instructed the coordinator to proceed without further questions.

**Status: researched and specified; NOT deployed.** The original planning-only/pane-only instructions blocked execution. At the operator's request, `CLAUDE.md` now permits scoped direct execution and native workers when Cockpit/cmux is unavailable. Implementation is authorized and pending; do not expose plaintext or claim deployment before live verification. No server state has been changed at this checkpoint.

### Verified prerequisites (read-only SSH)

- `fn` resolves to `andrius@173.208.50.216`; SSH succeeds with existing credentials.
- Linux x86_64; Docker 29.8.2; Compose 5.6.0; systemd and passwordless sudo available.
- No listeners observed on 80, 443, 3000, or 8080. External firewall reachability has NOT been established.
- Existing containers: `lcl`, `whisper-main`, and `FX`; leave these and their networks/data untouched.
- No matching existing `remote-pi` container or named volume observed.

### Official evidence

1. [Upstream Relay README](https://github.com/jacobaraujo7/remote_pi/blob/main/relay/README.md), fetched successfully; local `relay/README.md` has the same deployment/security guidance: official image `jacobmoura7/remote-pi-relay`, port 3000, persistent `/data`, `/health`, `/mesh/*`, and production TLS reverse proxy.
2. [Let's Encrypt IP certificates with Certbot](https://letsencrypt.org/2026/03/11/shorter-certs-certbot.html): public IP certificates are supported; use Certbot **5.4+** for webroot, `--ip-address`, and `--preferred-profile shortlived`. Certificates last about six days. Installation into the webserver needs explicit configuration and a renewal deploy hook.
3. [Certbot renewal documentation](https://eff-certbot.readthedocs.io/en/stable/using.html#renewing-certificates): reload after actual successful issuance with a deploy hook; an exit code of zero alone does not establish that renewal occurred.
4. [nginx WebSocket proxying](https://nginx.org/en/docs/http/websocket.html): forward Upgrade/Connection explicitly; default idle timeout is 60 seconds and must be reconciled with relay heartbeat behavior.
5. [nginx TLS protocols](https://nginx.org/en/docs/http/ngx_http_ssl_module.html#ssl_protocols): supports TLS 1.3 with a compatible OpenSSL build.
6. [Caddy automatic HTTPS](https://caddyserver.com/docs/automatic-https): bare-IP configuration must NOT be assumed to produce a publicly trusted certificate. Use the explicitly documented Certbot IP workflow rather than guessing version-specific Caddy ACME behavior.

## Expected structure

Implementation owner: **Relay**. Deployment files belong under `relay/` or a dedicated root-owned deployment directory on `fn`, not the monorepo planning root.

- Public client endpoint: **`wss://173.208.50.216`**.
- Docker Relay on a dedicated backend network, with **no published relay port**; nginx alone exposes public TCP 443 and ACME-only TCP 80.
- TLS 1.3, publicly trusted certificate with IP SAN `173.208.50.216`; no private CA installation, `-k`, or client verification bypass.
- TCP 80 serves only ACME HTTP-01 challenges; no relay traffic over HTTP.
- Persistent relay `/data`, certificate state, and ACME webroot. Proxy mounts certificate material read-only.
- Host-managed renewal schedule (e.g. every six hours with jitter/locking), tested deploy hook, and expiry/failure monitoring. No Docker socket mounted into containers.
- Pin reviewed image digests, record provenance/version compatibility, restart unless stopped, bounded logs, health checks, resource limits, least privilege.

This is the secure **direct-IP, existing-client-compatible** choice, not a claim of maximum security against every threat. A private VPN plus WSS further reduces exposure but requires additional client enrollment, which is not configured here. Self-hosting removes a third-party relay operator; it does not provide E2E encryption. Other workloads on this host remain part of the host-compromise risk.

## Steps and acceptance

1. **Preflight and provenance.** Recheck SSH target, ports, resources, and existing firewall rules. Verify the official image digest/release implements the current Relay protocol and membership migrations. Do not assume `latest` includes local fork changes. Inspect the exact image before applying an explicit non-root UID: local Dockerfile does not set `USER`; provision writable `/data` with restricted ownership first. Acceptance: recorded digest/version and no collisions with existing workloads.
2. **Isolated service configuration.** Use read-only root filesystem where compatible, writable volume only for `/data`, tmpfs for necessary temporary paths, `no-new-privileges`, dropped capabilities, no privileged/host networking, no host secrets or Docker socket mounts. Proxy should use unprivileged internal ports when practical. Keep upstream `/`, `/health`, and `/mesh/*` behavior intact. Acceptance: effective container settings inspected; database initialization and health check succeed under the chosen UID.
3. **IP certificate issuance.** Use Certbot 5.4+ from an official distribution, webroot mode, the short-lived profile, and `--ip-address 173.208.50.216`. Test issuance against staging using separate staging state, then issue production. Do not leave staging certificates installed. Review ACME subscriber terms before enrollment; do not invent a contact email. If ACME validation cannot succeed, keep relay unexposed and record the blocker; no plaintext fallback. Acceptance: trusted production chain and correct IP SAN.
4. **TLS proxy.** Enable TLS 1.3 only per `plan/00-decisions.md`; verify client compatibility rather than silently weakening it. Set HTTP/1.1 upstream, correct Upgrade/Connection map, and an idle timeout appropriate to actual heartbeat behavior. Preserve HTTP membership semantics and supported body limits. Disable payload/access logging where unnecessary; use bounded operational errors. Do not add unsupported Basic Auth or client-certificate requirements that break clients. Acceptance: HTTPS health succeeds with normal verification, WSS upgrade succeeds, and TLS <=1.2 is rejected.
5. **Renewal and recovery.** Schedule renewal without service downtime. Reload nginx only after successful issuance and successful configuration validation; do not copy staging certs into production during tests. Test renewal with `--dry-run` and explicitly exercise the deploy hook. Verify timer persistence at reboot, alert before expiry (at least 48 hours remaining), and keep renewal logs free of secrets. Acceptance: timer, dry-run, reload, and expiry inspection evidence captured.
6. **Network hardening.** Never publish port 3000 on any host interface. Preserve SSH and unrelated services; do not flush firewall tables or assume UFW protects Docker-published ports. Assess existing host/provider filtering before narrow additions. Acceptance: 443 is reachable externally, 80 serves ACME only, and 3000 is inaccessible externally over IPv4 and IPv6 where applicable.
7. **Functional acceptance.** Use temporary test identities for Ed25519 handshake/route tests, never overwrite real pairing keys. Test rejection of invalid authentication and membership signatures; do not mutate real Owner state. Verify expected connected routing behavior with compatible endpoints and reconnect behavior. A health response or unauthenticated 101 alone is not end-to-end protocol acceptance. Acceptance: distinct health, WSS, auth, and route test outcomes documented.
8. **Persistence and operations.** Perform a service/container restart rather than rebooting this shared host. Verify volume persistence, proxy reconnects, and unchanged unrelated workloads. Make a consistent SQLite backup using its backup API or a brief coordinated stop; do not copy a live rollback-journal database blindly. Restrict backup access and retain prior pinned image/config for rollback. Acceptance: successful restore test into isolated storage and deployment handoff containing endpoint, resource names, maintenance, and rollback commands.

## Definition of Done

- [x] Official relay and IP-certificate documentation checked.
- [x] SSH/Docker prerequisites verified read-only.
- [x] IP-only TLS deployment and fail-closed policy specified.
- [ ] Eligible Relay worker receives implementation handoff.
- [ ] Containers deployed with persistent storage and reviewed least privilege.
- [ ] Trusted IP certificate, TLS 1.3, and automated renewal verified.
- [ ] External network, authentication, routing, and restart checks pass.
- [ ] Backup/restore and rollback evidence recorded.
- [ ] Final working WSS endpoint reported; client migration status stated accurately.

## Next plans

Execute through a scoped native Relay worker or directly from `relay/`, per the updated orchestration instructions. Do not change this coordinator's active relay or existing user pairing configuration until the new endpoint is verified; report separately whether any clients were migrated. Design refinement is tracked independently in plan 93.
