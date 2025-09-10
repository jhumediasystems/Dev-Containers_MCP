#!/usr/bin/env bash
set -euo pipefail

exec 3>&1
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PYTHONWARNINGS="ignore"

WS="${CODEUSE_WORKSPACE:-$PWD}"
VENV="$WS/.mcp/.venv"

if command -v python3 >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1; then
  PY="python"
else
  echo "Python not found in container. Please add python3 to your dev image." >&2
  exit 1
fi

if [ ! -x "$VENV/bin/python" ]; then
  "$PY" -m venv "$VENV" >/dev/null 2>&1
  "$VENV/bin/pip" install -U pip >/dev/null 2>&1
  "$VENV/bin/pip" install -r "$WS/.mcp/agent/requirements.txt" >/dev/null 2>&1
fi

exec "$VENV/bin/python" -u "$WS/.mcp/agent/server.py"

