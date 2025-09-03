#!/usr/bin/env bash
set -euo pipefail

ROOT="${PWD}"
MCP_DIR=".mcp/agent"
VSC_DIR=".vscode"

mkdir -p "$MCP_DIR" "$VSC_DIR"

# ---- server.py (stdio MCP server: sh.exec + repo://{path}) -------------------
cat > "$MCP_DIR/server.py" << 'PY'
#!/usr/bin/env python3
import os, subprocess
from pathlib import Path
from typing import Optional

try:
    # Prefer the official Python SDK's FastMCP if available, else fall back to fastmcp
    from mcp.server.fastmcp import FastMCP  # type: ignore
except Exception:
    from fastmcp import FastMCP  # type: ignore

MCP = FastMCP("codeuse-agent")

# Workspace root passed by VS Code; fall back to CWD just in case.
ROOT = Path(os.environ.get("CODEUSE_WORKSPACE", os.getcwd())).resolve()

def _safe_join(p: Optional[str]) -> Path:
    path = (ROOT / (p or ".")).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Path escapes workspace")
    return path

@MCP.tool("sh.exec")
def sh_exec(cmd: str, cwd: str = ".", timeout_sec: int = 180) -> str:
    """
    Run a shell command inside the container with full image toolchain.
    Args:
      cmd: command string (e.g., 'latexmk -pdf main.tex' or 'bash script.sh')
      cwd: working dir relative to workspace
      timeout_sec: hard timeout in seconds
    Returns: combined stdout/stderr (truncated to 200k chars)
    """
    workdir = _safe_join(cwd)
    res = subprocess.run(
        ["/bin/bash", "-lc", cmd],
        cwd=str(workdir),
        text=True,
        capture_output=True,
        timeout=int(timeout_sec),
    )
    out = (res.stdout or "") + (("\n" + res.stderr) if res.stderr else "")
    # Keep responses prompt-friendly
    return out[-200_000:] if len(out) > 200_000 else out

@MCP.resource("repo://{path}")
def repo_read(path: str = "") -> str:
    """
    Read files or list directories within the workspace.
    - 'repo://' or 'repo://path/to/dir' -> newline-separated listing
    - 'repo://path/to/file' -> file contents (truncated to 200k chars)
    """
    target = _safe_join(path)
    if target.is_dir():
        items = []
        for child in sorted(target.iterdir()):
            suffix = "/" if child.is_dir() else ""
            items.append(child.name + suffix)
        return "\n".join(items)
    else:
        try:
            data = target.read_text(encoding="utf-8", errors="replace")
        except Exception as e:
            return f"[read error] {e}"
        return (data[:200_000] + "\n…[truncated]") if len(data) > 200_000 else data

if __name__ == "__main__":
    # stdio transport (works with VS Code/Copilot MCP)
    MCP.run()
PY
chmod +x "$MCP_DIR/server.py"

# ---- requirements.txt --------------------------------------------------------
# Try official 'mcp' SDK first; fall back to 'fastmcp' if not present in image.
cat > "$MCP_DIR/requirements.txt" << 'REQ'
# Prefer the official MCP SDK. If it isn't available for some reason, FastMCP works too.
mcp>=1.1 ; python_version >= "3.8"
fastmcp>=2.0
REQ

# ---- .vscode/mcp.json (runs in the *container* via stdio) --------------------
# Creates a venv under .mcp/.venv on first launch, installs deps, then execs server.py.
MCP_JSON="$VSC_DIR/mcp.json"
if [ -f "$MCP_JSON" ] && grep -q '"codeuse"' "$MCP_JSON"; then
  echo "• .vscode/mcp.json already defines 'codeuse' — not changing it."
else
  cat > "$MCP_JSON" << 'JSON'
{
  "servers": {
    "codeuse": {
      "command": "bash",
      "args": [
        "-lc",
        "set -euo pipefail; VENV=\"${workspaceFolder}/.mcp/.venv\"; PY=${PY:-python3}; \
if [ ! -x \"$VENV/bin/python\" ]; then \
  $PY -m venv \"$VENV\"; \
  \"$VENV/bin/pip\" install -U pip; \
  \"$VENV/bin/pip\" install -r \"${workspaceFolder}/.mcp/agent/requirements.txt\"; \
fi; \
exec \"$VENV/bin/python\" -u \"${workspaceFolder}/.mcp/agent/server.py\""
      ],
      "env": {
        "CODEUSE_WORKSPACE": "${workspaceFolder}"
      }
    }
  }
}
JSON
fi

# ---- helpful ignore (optional) ----------------------------------------------
if [ -f .gitignore ] && ! grep -q '^\.mcp/\.venv$' .gitignore; then
  printf "\n# MCP server venv\n.mcp/.venv\n" >> .gitignore
fi

echo "✅ Added MCP server. Next steps:"
echo "   1) Reopen this folder in container (Dev Containers: Rebuild/Reload)."
echo "   2) In Copilot Chat, open the Tools picker and enable 'codeuse'."
echo "   3) Try: 'List repo files via repo://', or 'Run: latexmk -pdf examples/tikz-main.tex'."

