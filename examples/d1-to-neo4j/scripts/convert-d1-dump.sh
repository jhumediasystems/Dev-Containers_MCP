#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/../resources/d1-to-neo4j"

if [ ! -d "$RESOURCES_DIR" ]; then
  echo "[convert-d1-dump] Expected repo at $RESOURCES_DIR. Clone your D1 conversion scripts there." >&2
  exit 1
fi

INPUT="${1:-}"
OUTPUT_GRAPH="${2:-neo4j}"

ENTRYPOINT=""
if [ -x "$RESOURCES_DIR/convert.sh" ]; then
  ENTRYPOINT="$RESOURCES_DIR/convert.sh"
elif [ -x "$RESOURCES_DIR/scripts/convert.sh" ]; then
  ENTRYPOINT="$RESOURCES_DIR/scripts/convert.sh"
elif [ -f "$RESOURCES_DIR/convert.py" ]; then
  ENTRYPOINT="$RESOURCES_DIR/convert.py"
elif [ -f "$RESOURCES_DIR/main.py" ]; then
  ENTRYPOINT="$RESOURCES_DIR/main.py"
fi

if [ -z "$ENTRYPOINT" ]; then
  echo "[convert-d1-dump] Could not find convert.sh or convert.py entrypoint in $RESOURCES_DIR." >&2
  echo "Provide your own script and re-run." >&2
  exit 2
fi

set -x
if [[ "$ENTRYPOINT" == *.py ]]; then
  if [ -d "$PROJECT_ROOT/.venv/d1neo4j" ]; then
    # shellcheck disable=SC1091
    source "$PROJECT_ROOT/.venv/d1neo4j/bin/activate"
  fi
  python "$ENTRYPOINT" ${INPUT:+"$INPUT"} ${OUTPUT_GRAPH:+"$OUTPUT_GRAPH"}
else
  bash "$ENTRYPOINT" ${INPUT:+"$INPUT"} ${OUTPUT_GRAPH:+"$OUTPUT_GRAPH"}
fi
