#!/usr/bin/env bash
set -euo pipefail

echo "[onCreate] Verifying shared tooling (Node, Wrangler, Neo4j)..."

export NVM_DIR="${NVM_DIR:-}"
export HOME="${HOME:-/home/node}"

if [ -f .nvmrc ]; then
  TARGET_NODE="$(cat .nvmrc)"
  CURRENT_NODE="$(node -v 2>/dev/null | sed 's/^v//' || echo "unknown")"
  if [ "$CURRENT_NODE" != "$TARGET_NODE" ]; then
    NVM_SCRIPT=""
    if [ -n "${NVM_DIR:-}" ] && [ -s "${NVM_DIR%/}/nvm.sh" ]; then
      NVM_SCRIPT="${NVM_DIR%/}/nvm.sh"
    elif [ -s "$HOME/.nvm/nvm.sh" ]; then
      NVM_SCRIPT="$HOME/.nvm/nvm.sh"
    elif [ -s "/usr/local/share/nvm/nvm.sh" ]; then
      NVM_SCRIPT="/usr/local/share/nvm/nvm.sh"
    fi

    if [ -n "$NVM_SCRIPT" ]; then
      # shellcheck disable=SC1090
      if . "$NVM_SCRIPT" 2>/dev/null && command -v nvm >/dev/null 2>&1; then
        echo "[onCreate] Installing Node $TARGET_NODE via nvm..."
        nvm install "$TARGET_NODE" >/dev/null 2>&1 || nvm install "$TARGET_NODE" 2>/dev/null || true
        nvm use "$TARGET_NODE" 2>/dev/null || true
      else
        echo "[onCreate] Unable to source nvm; continuing with system Node ($CURRENT_NODE)."
      fi
    else
      echo "[onCreate] .nvmrc found but nvm unavailable; using system Node ($CURRENT_NODE)."
    fi
  fi
fi

node -v || true
npm -v || true
wrangler --version || true
python3 --version || true
java -version || true
neo4j --version || true
cypher-shell --version || true

echo "[onCreate] Preparing persistent Neo4j data directory..."
NEO4J_WORKSPACE_DATA="${PWD}/data/neo4j"
mkdir -p "$NEO4J_WORKSPACE_DATA"
if ! sudo test -L /var/lib/neo4j/data; then
  sudo rm -rf /var/lib/neo4j/data
  sudo ln -s "$NEO4J_WORKSPACE_DATA" /var/lib/neo4j/data
fi
sudo chown -R neo4j:neo4j "$NEO4J_WORKSPACE_DATA"

echo "[onCreate] Ensuring initial Neo4j password (see README to change)..."
if ! sudo test -f "$NEO4J_WORKSPACE_DATA/dbms/auth"; then
  sudo neo4j-admin dbms set-initial-password d1neo4j 2>/dev/null || true
fi

echo "[onCreate] Bootstrapping Python virtual environment for D1 converters if requested..."
PY_ENV=".venv/d1neo4j"
REQ_FILE="resources/d1-to-neo4j/requirements.txt"
if [ -f "$REQ_FILE" ]; then
  python3 -m venv "$PY_ENV"
  # shellcheck disable=SC1091
  source "$PY_ENV/bin/activate"
  pip install --upgrade pip >/dev/null 2>&1 || true
  pip install -r "$REQ_FILE"
  deactivate
fi

echo "[onCreate] D1 to Neo4j workstation ready. Use scripts/start-neo4j-console.sh to launch the database."
