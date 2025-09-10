# Cloudflare Workers Workstation

**Node version pinning:**
This devcontainer uses the official devcontainers Node image from MCR (mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm) and pins Node.js to 22.14.0 via `.nvmrc`. The container will use the closest available Node 22.x version by default, but if you have `nvm` installed, the onCreate script will enforce the exact version from `.nvmrc`.

**Miniflare install:**
Miniflare is no longer installed globally, as its CLI is deprecated and `wrangler dev` now provides the local emulation runtime. All local development should use `wrangler dev`.

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


## Local vs. Cloudflare Deployment: Best Practices

### Local Development (wrangler dev / Miniflare)

- Use `wrangler dev` to run your worker locally. This uses Miniflare under the hood, providing emulation for KV, D1 (with SQLite), R2, and Durable Objects.
- Local D1 data is stored in SQLite files; R2 and KV are in-memory or file-backed (see Miniflare docs for advanced config).
- You do **not** need a Cloudflare account or credentials for local testing. Default bindings are auto-provisioned if not set in `.env`.
- Example:
  ```sh
  cd workers/deploy/wrangler-cli_test
  wrangler dev index.js --port 8787
  # Visit http://localhost:8787
  ```

### Deploying to Cloudflare (live)

- Run `wrangler deploy index.js` to push your worker to Cloudflare. This requires authentication (`wrangler login` or `CLOUDFLARE_API_TOKEN`).
- Ensure `.env` values for D1, R2, and KV match real resources in your Cloudflare account. The deploy will fail if names/IDs are missing or incorrect.
- After deploy, test your endpoint using the live Cloudflare URL (shown in wrangler output).

### Node.js vs. Cloudflare Workers Platform

- Cloudflare Workers run on a V8 isolate, not a full Node.js runtime. **Not all Node.js APIs or libraries are supported.**
- **Allowed:**
  - Standard JS/ESM modules, fetch, Web Crypto, URL, TextEncoder/Decoder, etc.
  - Most npm packages that are pure JS and do not require Node built-ins or native modules.
- **Not allowed:**
  - Node built-ins like `fs`, `net`, `child_process`, `os`, `path`, etc.
  - Native modules (anything that needs to be compiled or links to C/C++ code).
  - Synchronous APIs (Cloudflare is async-only).
- **Best practices:**
  - Use ESM syntax (`import`/`export`) for maximum compatibility.
  - Check your dependencies: use `wrangler dev --local` to catch issues early, but always test deploy to Cloudflare before relying on a package.
  - If you need a library, check if it is [Cloudflare-compatible](https://developers.cloudflare.com/workers/wrangler/compatibility-dates/#supported-apis).
  - For crypto, use the Web Crypto API (`crypto.subtle`), not Node's `crypto` module.
  - For HTTP requests, use `fetch` (global in Workers).
  - Avoid any code that assumes a filesystem or process environment.

### Debugging Local vs. Live Differences

- Some subtle differences exist between Miniflare (local) and Cloudflare (live):
  - Miniflare is very close, but not 100% identical to production Workers.
  - Always do a test deploy before shipping to production.
  - Use `wrangler tail` to stream logs from your live worker for debugging.
- If you see errors locally but not live (or vice versa):
  - Check for use of unsupported Node APIs.
  - Check for missing or misconfigured bindings in `.env` or `wrangler.toml`.
  - Compare your compatibility date in `wrangler.toml` to the latest supported by Cloudflare.

### D1, R2, and KV: Local vs. Cloudflare

- **D1:**
  - Local: Backed by SQLite, fast for dev/test. Data is not shared with Cloudflare.
  - Live: Real D1 database in your Cloudflare account. Data is persistent and globally available.
- **R2:**
  - Local: Miniflare emulates R2 buckets. Data is not shared with Cloudflare.
  - Live: Real R2 bucket in your Cloudflare account.
- **KV:**
  - Local: Miniflare emulates KV. Data is not shared with Cloudflare.
  - Live: Real KV namespace in your Cloudflare account.

**Tip:** For production-like testing, seed your local D1/KV/R2 with representative data, but remember that local and live data are always separate.

---

- The workflow is nested under `examples/cloudflare-workstation/.github` so it will not affect this monorepo; it is intended for when this example is used as a standalone template.
- You can add VS Code extensions to `.devcontainer/devcontainer.json` under `customizations.vscode.extensions` as desired.
