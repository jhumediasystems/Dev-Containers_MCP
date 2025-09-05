#!/usr/bin/env bash
set -euo pipefail

echo "[onCreate] Verifying Python and jq..."
python3 --version || true
jq --version || true

echo "[onCreate] Generating MCP server scaffolding from current devcontainer..."
bash scripts/add-mcp-to-devcontainer.sh .devcontainer .devcontainer/Dockerfile || true

echo "[onCreate] Done. Open VS Code Command Palette: 'List MCP Servers' to start the 'codeuse' server."

