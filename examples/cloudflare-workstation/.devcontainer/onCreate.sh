#!/usr/bin/env bash
set -euo pipefail

echo "[onCreate] Verifying global tools..."
node -v || true
npm -v || true
wrangler --version || true
miniflare --version || true

echo "[onCreate] Installing project-local deps if a worker exists..."
if [ -f "workers/deploy/wrangler-cli_test/package.json" ]; then
  (cd workers/deploy/wrangler-cli_test && npm ci || npm install)
fi

echo "[onCreate] If .env exists, render wrangler.toml from template..."
if [ -f ".env" ] && [ -f "scripts/apply-env-to-wrangler.sh" ]; then
  bash scripts/apply-env-to-wrangler.sh || true
fi

echo "[onCreate] Done. Use 'wrangler login' or set env vars to deploy."
