#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
NEO4J_DATA="$PROJECT_ROOT/data/neo4j"

if [ ! -d "$NEO4J_DATA" ]; then
  mkdir -p "$NEO4J_DATA"
  sudo chown -R neo4j:neo4j "$NEO4J_DATA"
fi

export NEO4J_HOME=/var/lib/neo4j
export JAVA_HOME=${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}

echo "[neo4j] Starting console with data dir $NEO4J_DATA (Ctrl+C to stop)..."
sudo --preserve-env=NEO4J_HOME,JAVA_HOME,NEO4J_AUTH neo4j console
