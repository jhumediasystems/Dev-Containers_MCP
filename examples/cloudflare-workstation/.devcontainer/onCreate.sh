#!/usr/bin/env bash
set -euo pipefail

echo "[onCreate] Verifying global tools..."

# If nvm and .nvmrc present, attempt to use specified Node version
if [ -f .nvmrc ] && [ -s "$NVM_DIR/nvm.sh" 2>/dev/null ] || [ -s "$HOME/.nvm/nvm.sh" ]; then
  # shellcheck disable=SC1090
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" || . "$HOME/.nvm/nvm.sh"
  TARGET_NODE="$(cat .nvmrc)"
  echo "[onCreate] Ensuring Node $TARGET_NODE via nvm..."
  nvm install "$TARGET_NODE" >/dev/null 2>&1 || nvm install "$TARGET_NODE" || true
  nvm use "$TARGET_NODE" || true
fi

node -v || true
npm -v || true
wrangler --version || true

echo "[onCreate] Installing project-local deps if a worker exists..."
if [ -f "workers/deploy/wrangler-cli_test/package.json" ]; then
  (cd workers/deploy/wrangler-cli_test && npm ci || npm install)
fi

echo "[onCreate] If .env exists, render wrangler.toml from template..."
if [ -f ".env" ] && [ -f "scripts/apply-env-to-wrangler.sh" ]; then
  bash scripts/apply-env-to-wrangler.sh || true
fi

echo "[onCreate] Done. Use 'wrangler login' or set env vars to deploy."
