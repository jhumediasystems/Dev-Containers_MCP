#!/usr/bin/env bash
set -euo pipefail

# Usage information
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  echo "Usage: $0 [DEVCONTAINER_DIR [DOCKERFILE]]"
  echo "Generate MCP server scaffolding for the current project."
  echo "DEVCONTAINER_DIR defaults to .devcontainer and DOCKERFILE to DEVCONTAINER_DIR/Dockerfile."
  exit 0
fi

DEVCONTAINER_DIR="${1:-.devcontainer}"
DOCKERFILE="${2:-$DEVCONTAINER_DIR/Dockerfile}"

ROOT="${PWD}"
MCP_DIR=".mcp/agent"
VSC_DIR=".vscode"
MCP_JSON="$VSC_DIR/mcp.json"
TOOLS_FILE="$MCP_DIR/tools.json"

mkdir -p "$MCP_DIR" "$VSC_DIR"

# -----------------------------------------------------------------------------
# Parse Dockerfile for packages
# -----------------------------------------------------------------------------
if [ -f "$DOCKERFILE" ]; then
  APT_PKGS=$(grep -E 'apt(-get)?\s+install' "$DOCKERFILE" | \
    sed -E 's/.*apt(-get)?\s+install[^a-zA-Z0-9]*//' | sed 's/&&.*//' | \
    tr '\\' ' ' | tr -s ' ' '\n' | \
    grep -vE '^$|\\|&&|-y|--no-install-recommends' | sort -u)
  PIP_PKGS=$(grep -E 'pip(3)?\s+install' "$DOCKERFILE" | \
    sed -E 's/.*pip(3)?\s+install[^a-zA-Z0-9]*//' | sed 's/&&.*//' | \
    tr '\\' ' ' | tr -s ' ' '\n' | \
    grep -vE '^$|\\|&&|-' | sort -u)
else
  APT_PKGS=""
  PIP_PKGS=""
fi

# -----------------------------------------------------------------------------
# Parse devcontainer features
# -----------------------------------------------------------------------------
DEVCONTAINER_JSON="$DEVCONTAINER_DIR/devcontainer.json"
FEATURES=""
if [ -f "$DEVCONTAINER_JSON" ] && command -v jq >/dev/null 2>&1; then
  FEATURES=$(jq -r '.features | keys[]?' "$DEVCONTAINER_JSON" 2>/dev/null || true)
fi

# -----------------------------------------------------------------------------
# Helper to convert newline lists to JSON arrays
# -----------------------------------------------------------------------------
json_array() {
  if command -v jq >/dev/null 2>&1; then
    if [ -n "$1" ]; then printf '%s\n' "$1" | jq -R . | jq -s .; else echo '[]'; fi
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$1" <<'PY'
import json, sys
items = [s for s in sys.argv[1].splitlines() if s.strip()]
print(json.dumps(items))
PY
  else
    printf '['
    local first=1
    while IFS= read -r line; do
      [ -z "$line" ] && continue
      if [ $first -eq 0 ]; then printf ', '; fi
      printf '%s' "\"$line\""
      first=0
    done <<< "$1"
    printf ']'
  fi
}

apt_json=$(json_array "$APT_PKGS")
pip_json=$(json_array "$PIP_PKGS")
feat_json=$(json_array "$FEATURES")

cat > "$TOOLS_FILE" <<EOF2
{
  "apt": $apt_json,
  "pip": $pip_json,
  "features": $feat_json
}
EOF2

# -----------------------------------------------------------------------------
# requirements.txt
# -----------------------------------------------------------------------------
cat > "$MCP_DIR/requirements.txt" <<'REQ'
fastmcp>=2.10,<3
REQ

# -----------------------------------------------------------------------------
# server.py
# -----------------------------------------------------------------------------
cat > "$MCP_DIR/server.py" <<'PY'
#!/usr/bin/env python3
import os, json, subprocess, shutil, platform
from pathlib import Path
from typing import Optional
from fastmcp import FastMCP

mcp = FastMCP("codeuse-agent")

ROOT = Path(os.environ.get("CODEUSE_WORKSPACE", os.getcwd())).resolve()
TOOLS_FILE = ROOT / ".mcp" / "agent" / "tools.json"
STATE_DIR = ROOT / ".mcp" / "state"
STATE_DIR.mkdir(parents=True, exist_ok=True)
ENV_SUMMARY_FILE = STATE_DIR / "env-summary.json"

def _safe_join(p: Optional[str]) -> Path:
    path = (ROOT / (p or ".")).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Path escapes workspace")
    return path

def _which(name: str) -> str:
    return shutil.which(name) or ""

def _cmd_version(cmd: str) -> str:
    try:
        out = subprocess.run(["/bin/bash","-lc", cmd], text=True,
                             capture_output=True, timeout=15)
        s = (out.stdout or out.stderr or "").strip()
        return s.splitlines()[0][:200]
    except Exception as e:
        return f"err: {e}"

def _load_tools():
    if TOOLS_FILE.exists():
        return json.loads(TOOLS_FILE.read_text(encoding="utf-8"))
    return {}

def _generate_env_summary() -> dict:
    return {
        "workspace": str(ROOT),
        "os": {
            "platform": platform.system(),
            "release": platform.release(),
        },
        "paths": {
            "python": _which("python3") or _which("python"),
            "node": _which("node"),
        },
        "versions": {
            "python": _cmd_version("python3 --version || python --version"),
            "node": _cmd_version("node --version"),
        },
        "tools": _load_tools(),
    }

@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _generate_env_summary()
        ENV_SUMMARY_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)

@mcp.tool(name="run_commands")
def run_commands(cmds: list[str], cwd: str = ".", stop_on_error: bool = True, timeout_sec: int = 300) -> str:
    workdir = _safe_join(cwd)
    lines = []
    for cmd in cmds:
        proc = subprocess.run([
            "/bin/bash", "-lc", cmd
        ], cwd=workdir, text=True, capture_output=True, timeout=timeout_sec)
        lines.append(f"$ {cmd}\n{proc.stdout}{proc.stderr}")
        if stop_on_error and proc.returncode != 0:
            break
    return "\n".join(lines)

if __name__ == "__main__":
    mcp.run()
PY
chmod +x "$MCP_DIR/server.py"

# -----------------------------------------------------------------------------
# start.sh
# -----------------------------------------------------------------------------
cat > "$MCP_DIR/start.sh" <<'SH'
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
SH
chmod +x "$MCP_DIR/start.sh"

# -----------------------------------------------------------------------------
# VS Code MCP config
# -----------------------------------------------------------------------------
cat > "$MCP_JSON" <<'JSON'
{
  "servers": {
    "codeuse": {
      "type": "stdio",
      "command": "bash",
      "args": ["-lc", "exec \"$CODEUSE_WORKSPACE/.mcp/agent/start.sh\""],
      "env": {
        "CODEUSE_WORKSPACE": "${workspaceFolder}"
      }
    }
  }
}
JSON

echo "Generated MCP server files in $MCP_DIR and VS Code config at $MCP_JSON"
