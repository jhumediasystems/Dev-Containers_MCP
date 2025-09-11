Goal: Cloudflare Workers development with Wrangler/Miniflare, local emulation of KV/R2/D1, and CI deploys.

Requirements:
- Base on `ghcr.io/devcontainers/images/javascript-node` (Node 20+).
- Global tools: wrangler, miniflare.
- OS deps: sqlite3 for D1 local storage.
- VS Code extensions: eslint/prettier; optional Cloudflare extension.
- Ports: 8787 for `wrangler dev`.
- onCreate.sh: verify wrangler/miniflare; render wrangler.toml from `.env` template if present.
- Include a GitHub Actions workflow to deploy workers in `workers/deploy/*` on push to a `live` branch.

