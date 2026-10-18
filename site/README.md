# Website

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

`pnpm build` first synchronizes `public/install.sh` from the extension installer, then builds Next.js. The Dockerfile packages standalone output and listens on port 3000:

```sh
docker build -t remote-pi-site .
docker run --rm -p 127.0.0.1:3000:3000 remote-pi-site
```

For an independent deployment, review upstream legal/operator text, links, update manifests, download hosts and `push-docker.sh` destinations first. Do not publish to upstream infrastructure. Put the site behind your own TLS proxy and configure credentials outside Git.
