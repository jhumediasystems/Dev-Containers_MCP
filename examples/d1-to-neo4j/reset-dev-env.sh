#!/usr/bin/env bash
set -euo pipefail

log() { echo "[reset-d1-neo4j] $*"; }

WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

log "1/7 Clearing stale VS Code server bins (auto reinstalls on reconnect)..."
rm -rf ~/.vscode-server/bin/* || true

log "2/7 Pruning dangling Docker build cache (no named images removed)..."
docker buildx prune -f || true

docker image prune -f || true

log "3/7 Pulling latest base devcontainer image..."
BASE_IMAGE="ghcr.io/devcontainers/javascript-node:1-22-bookworm"
docker pull "$BASE_IMAGE" || true

log "4/7 Updating devcontainer CLI if available..."
if command -v npm >/dev/null 2>&1; then
  npm install -g @devcontainers/cli >/dev/null 2>&1 || npm install -g @devcontainers/cli || true
else
  log "npm not found; skipping devcontainer CLI update"
fi

log "5/7 Recreating dev container for $WORKSPACE_DIR..."
if command -v devcontainer >/dev/null 2>&1; then
  devcontainer up --workspace-folder "$WORKSPACE_DIR" || log "devcontainer up failed; review logs above"
else
  log "devcontainer CLI not installed; skipping container bring-up"
fi

log "6/7 Listing running containers with relevant ports..."
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' || true

log "7/7 Done. Neo4j data in examples/d1-to-neo4j/data persists across rebuilds."
