# Website

[Project index](../README.md#project-map)

Next.js 16 / React 19 website with Tailwind 4. Maintainer and author of contributions: **Andrius Solopovas**.

Use Node 22 (as in the Dockerfile) and pnpm. Run from this directory:

```sh
pnpm install --frozen-lockfile
pnpm dev                       # localhost:3000
pnpm lint
pnpm build
pnpm start
```

Routes under `src/app/` include the Cockpit landing/docs/download/tutorial pages, `/remote-pi` and its guides, and `/terms` and `/privacy`. This is a presentation site, not the agent or relay server. Transport security is described in [PROTOCOL.md](../PROTOCOL.md); do not claim systemwide E2E encryption.

## Integrations

- Product setup belongs to the [mobile client](../app/README.md), [host extension](../pi-extension/README.md), [relay](../relay/README.md) and [Cockpit](../cockpit/README.md) guides; site routes present that product documentation to visitors.
- `pnpm build` synchronizes [public/install.sh](public/install.sh) from the [extension installer](../pi-extension/install.sh). Cockpit's [server installer](../cockpit/install-server.sh) is a separate delivery path.
- The [Cockpit manifest reader](src/lib/cockpit-release.ts) consumes [download-server manifests](../rp-s3/README.md#integrations). [Release packaging](../cockpit/packaging/README.md) owns their production and signing, not this website.
- [Remote Pi artwork](../branding/README.md) and [Cockpit artwork](../cockpit/assets/branding/) are separate sources; do not assume one generates the other.

## Deploy and maintain

The [Dockerfile](Dockerfile) packages standalone output and listens on port 3000:

```sh
docker build -t remote-pi-site .
docker run --rm -p 127.0.0.1:3000:3000 remote-pi-site
```

For an independent deployment, review upstream legal/operator text, links, update manifests, download hosts and `push-docker.sh` destinations first. Do not publish to upstream infrastructure. The [image publisher](push-docker.sh) requires an explicit destination under the [publisher guards](../SECURITY.md#local-publisher-guards). Put the site behind your own TLS proxy and configure credentials outside Git. Follow [site development rules](CLAUDE.md) and the shared [security/publication gates](../SECURITY.md).
