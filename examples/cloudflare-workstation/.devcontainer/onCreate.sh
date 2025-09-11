#!/usr/bin/env bash
set -euo pipefail

echo "[onCreate] Verifying global tools..."

# Set default values for potentially unset variables
export NVM_DIR="${NVM_DIR:-}"
export HOME="${HOME:-/home/node}"

# If .nvmrc present, attempt to use specified Node version (only if nvm is available)
if [ -f .nvmrc ]; then
  TARGET_NODE="$(cat .nvmrc)"
  CURRENT_NODE="$(node -v 2>/dev/null | sed 's/^v//' || echo "unknown")"
  
  # If we already have the target Node version, skip NVM setup
  if [ "$CURRENT_NODE" = "$TARGET_NODE" ]; then
    echo "[onCreate] Node $TARGET_NODE already active, skipping NVM setup."
  else
    NVM_SCRIPT=""
    # Prefer explicit NVM_DIR if set
    if [ -n "${NVM_DIR:-}" ] && [ -s "${NVM_DIR%/}/nvm.sh" ]; then
      NVM_SCRIPT="${NVM_DIR%/}/nvm.sh"
    elif [ -s "$HOME/.nvm/nvm.sh" ]; then
      NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
      # Devcontainers Node images often install here
      NVM_SCRIPT="/usr/local/share/nvm/nvm.sh"
    fi

    if [ -n "$NVM_SCRIPT" ]; then
      # shellcheck disable=SC1090
      if . "$NVM_SCRIPT" 2>/dev/null; then
        if command -v nvm >/dev/null 2>&1; then
          echo "[onCreate] Ensuring Node $TARGET_NODE via nvm..."
          nvm install "$TARGET_NODE" >/dev/null 2>&1 || nvm install "$TARGET_NODE" 2>/dev/null || true
          nvm use "$TARGET_NODE" 2>/dev/null || true
        fi
      else
        echo "[onCreate] Failed to source NVM script; using system Node."
      fi
    else
      echo "[onCreate] .nvmrc found but nvm not installed; using system Node ($CURRENT_NODE)."
    fi
  fi
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
