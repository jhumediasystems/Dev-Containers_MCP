# Cloudflare Workers Workstation

A devcontainer-based workstation for building, testing (locally), and deploying Cloudflare Workers with Wrangler. It mirrors the structure of `examples/latex-workstation` and incorporates the functionality from the `examples/building/cloudflareworker-deploy_template` sample.

- Base: `ghcr.io/devcontainers/images/javascript-node` (widely used official devcontainers base)
- Tools: `wrangler` and `miniflare` installed globally for local development
- Local emulation: `wrangler dev` via Miniflare supports KV, Durable Objects, R2, and D1 (D1 backed by SQLite). `sqlite3` is available in the image for D1 inspection/debugging.
- Deployment: a GitHub Action to auto-deploy worker directories on branch `live` using repository secrets

## Quick Start

1. Open this folder in a Codespace or VS Code Dev Containers.
2. Let the container build. The onCreate script verifies `node`, `npm`, `wrangler`, and `miniflare`.
3. Try local dev for the sample worker:

```
cd workers/deploy/wrangler-cli_test
wrangler dev index.js --port 8787
# Visit http://localhost:8787
```

The sample uses KV, D1, and R2 bindings. In local mode, Miniflare provides them automatically. If a binding is missing, the code fails gracefully.

## Configure D1, R2, KV via .env

1. Copy `.env.example` to `.env` and fill values:

   - `GREETING`: worker runtime example var
   - `D1_DATABASE_NAME`: existing D1 database name in your account (Wrangler resolves by name)
   - `R2_BUCKET_NAME`: existing R2 bucket name
   - `KV_NAMESPACE_ID`: KV namespace ID

2. Render `wrangler.toml` from the template using the helper script:

```
cd examples/cloudflare-workstation
bash scripts/apply-env-to-wrangler.sh
```

This produces `workers/deploy/wrangler-cli_test/wrangler.toml` from `wrangler.toml.template` by substituting values from `.env`.

3. For local dev, `.env` is not required; defaults are used. For deploys, ensure the names/IDs in `.env` match resources in your Cloudflare account.

## Wrangler Auth

- Local testing does not require credentials.
- For deploying to Cloudflare: either run `wrangler login` (interactive) or set environment variables in the container session:
  - `CLOUDFLARE_API_TOKEN` (recommended)
  - (Optional legacy) `CLOUDFLARE_EMAIL`

Then deploy:

```
wrangler deploy index.js
```

## Repository Secrets & CI

A workflow is included at `examples/cloudflare-workstation/.github/workflows/autodeploy-workers-onpush.yml`. When this folder is used as a template for its own repository, add Secrets in that repository:

- Actions > Secrets and variables > Actions
  - `CLOUDFLARE_API_TOKEN`: API token with Workers edit and (if needed) R2 permissions
  - `CLOUDFLARE_EMAIL`: optional; some org setups still use it

Push to branch `live` and the workflow deploys each worker found in `workers/deploy/*/` that contains `index.js` and `wrangler.toml`.

## Worker Layout

- `workers/deploy/wrangler-cli_test/index.js`: sample worker using KV, D1, and R2
- `workers/deploy/wrangler-cli_test/wrangler.toml.template`: template with placeholders rendered from `.env`
- `workers/deploy/wrangler-cli_test/wrangler.toml`: generated file, ignored in VCS, used by Wrangler

Bindings are referenced by name in the code:

- `KV`: KV namespace
- `DB`: D1 Database
- `BUCKET`: R2 bucket

Adjust `wrangler.toml` values for your Cloudflare account before deploying.

## Image Choice Rationale

- `ghcr.io/devcontainers/images/javascript-node` is the official devcontainers Node image family with broad use and active maintenance.
- Installing `wrangler` and `miniflare` globally preserves your existing Wrangler-based workflows and enables full-featured local development (Miniflare v3 uses the same runtime as Cloudflare Workers and provides D1/KV/R2/Durable Objects emulation).
- `sqlite3` is included for D1 troubleshooting (local Miniflare stores D1 data in SQLite files).

## Common Commands

- Local dev: `wrangler dev index.js --port 8787`
- Deploy: `wrangler deploy index.js`
- D1 shell (local): `wrangler d1 execute <DB_NAME> --local --command 'select 1;'`

### Create resources (optional helpers)

- D1 (once): `wrangler d1 create <NAME>` then set `D1_DATABASE_NAME=<NAME>` in `.env`
- R2 bucket (once): `wrangler r2 bucket create <BUCKET>` then set `R2_BUCKET_NAME=<BUCKET>` in `.env`
- KV namespace (once): `wrangler kv namespace create <NAMESPACE>` then set `KV_NAMESPACE_ID=<ID>` in `.env`

## Notes

- The workflow is nested under `examples/cloudflare-workstation/.github` so it will not affect this monorepo; it is intended for when this example is used as a standalone template.
- You can add VS Code extensions to `.devcontainer/devcontainer.json` under `customizations.vscode.extensions` as desired.
