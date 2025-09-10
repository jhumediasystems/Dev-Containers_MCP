#!/usr/bin/env bash
set -euo pipefail

ROOT="${PWD}"
MCP_DIR=".mcp/agent"
VSC_DIR=".vscode"
MCP_JSON="$VSC_DIR/mcp.json"

mkdir -p "$MCP_DIR" "$VSC_DIR"

# ---- server.py (FastMCP-only: sh_exec + env_summary + run_commands + resources) ---
cat > "$MCP_DIR/server.py" << 'PY'
#!/usr/bin/env python3
import os, subprocess, json, shutil, platform
from pathlib import Path
from typing import Optional

# Use FastMCP only (simpler & stable decorator API)
from fastmcp import FastMCP

mcp = FastMCP("codeuse-agent")

# Workspace root passed by VS Code; fall back to CWD just in case.
ROOT = Path(os.environ.get("CODEUSE_WORKSPACE", os.getcwd())).resolve()

STATE_DIR = ROOT / ".mcp" / "state"
STATE_DIR.mkdir(parents=True, exist_ok=True)
ENV_SUMMARY_FILE = STATE_DIR / "env-summary.json"

def _safe_join(p: Optional[str]) -> Path:
    path = (ROOT / (p or ".")).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Path escapes workspace")
    return path

def _which(name: str) -> str:
    p = shutil.which(name)
    return p or ""

def _cmd_version(cmd: str) -> str:
    try:
        out = subprocess.run(["/bin/bash","-lc", cmd], text=True,
                             capture_output=True, timeout=15)
        s = (out.stdout or out.stderr or "").strip()
        return s.splitlines()[0][:200]
    except Exception as e:
        return f"err: {e}"

def _detect_project() -> dict:
    d = {
        "latex": any((ROOT / n).exists() for n in ["latexmkrc",".latexmkrc"]) or
                 any(str(p).endswith(".tex") for p in ROOT.rglob("*.tex")),
        "node": (ROOT / "package.json").exists(),
        "python": (ROOT / "pyproject.toml").exists() or (ROOT / "requirements.txt").exists(),
        "make": (ROOT / "Makefile").exists(),
    }
    suggestions = []
    if d["latex"]:
        suggestions.append("latexmk -pdf -interaction=nonstopmode -file-line-error %DOC%")
    if d["make"]:
        suggestions.append("make")
    if d["node"]:
        suggestions.append("npm test || npm run build")
    if d["python"]:
        suggestions.append("pytest -q || python -m build")
    return {"detected": d, "suggestedCommands": suggestions}

def _generate_env_summary() -> dict:
    summary = {
        "workspace": str(ROOT),
        "os": {
            "platform": platform.system(),
            "release": platform.release(),
            "distro": _cmd_version("sed -n 's/^PRETTY_NAME=//p' /etc/os-release | tr -d '\"'")
        },
        "paths": {
            "python": _which("python3") or _which("python"),
            "pip": _which("pip") or _which("pip3"),
            "node": _which("node"),
            "npm": _which("npm"),
            "latexmk": _which("latexmk"),
            "pandoc": _which("pandoc"),
            "biber": _which("biber"),
            "miktex": _which("miktexsetup") or _which("mpm"),
        },
        "versions": {
            "python": _cmd_version("python3 --version || python --version"),
            "pip": _cmd_version("pip --version || pip3 --version"),
            "node": _cmd_version("node --version"),
            "npm": _cmd_version("npm --version"),
            "latexmk": _cmd_version("latexmk -v | head -n 1"),
            "pandoc": _cmd_version("pandoc -v | head -n 1"),
            "biber": _cmd_version("biber --version | head -n 1"),
            "miktex": _cmd_version("mpm --version | head -n 1 || miktexsetup --version | head -n 1")
        },
        "env": {
            "LANG": os.environ.get("LANG", ""),
            "PATH": (os.environ.get("PATH","")[:300] + ("…" if len(os.environ.get("PATH",""))>300 else ""))
        },
        "project": _detect_project()
    }
    return summary

@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    """
    Summarize container environment (tools, versions, workspace, suggested commands).
    Set refresh=true to rescan; pretty controls JSON formatting.
    """
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _generate_env_summary()
        ENV_SUMMARY_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)

@mcp.tool(name="run_commands")
def run_commands(cmds: list[str], cwd: str = ".", stop_on_error: bool = True, timeout_sec: int = 300) -> str:
    """
    Run a sequence of shell commands; returns a combined transcript.
    """
    workdir = _safe_join(cwd)
    lines = []
    for i, cmd in enumerate(cmds, 1):
        lines.append(f"$ {cmd}")
        try:
            res = subprocess.run(
                ["/bin/bash","-lc", cmd],
                cwd=str(workdir), text=True, capture_output=True, timeout=int(timeout_sec)
            )
            if res.stdout: lines.append(res.stdout.rstrip())
            if res.stderr: lines.append(res.stderr.rstrip())
            if res.returncode != 0 and stop_on_error:
                lines.append(f"[exit {res.returncode}]")
                break
            elif res.returncode != 0:
                lines.append(f"[nonzero exit {res.returncode}, continuing]")
        except subprocess.TimeoutExpired:
            lines.append("[timeout]")
            if stop_on_error: break
    out = "\n".join(lines)
    return out[-200_000:] if len(out) > 200_000 else out

@mcp.resource("env://summary")
def env_summary_resource() -> str:
    if not ENV_SUMMARY_FILE.exists():
        ENV_SUMMARY_FILE.write_text(json.dumps(_generate_env_summary(), indent=2), encoding="utf-8")
    return ENV_SUMMARY_FILE.read_text(encoding="utf-8")

@mcp.tool(name="sh_exec")
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
    return out[-200_000:] if len(out) > 200_000 else out

@mcp.resource("repo://{path}")
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
    mcp.run()
PY
chmod +x "$MCP_DIR/server.py"

# ---- requirements.txt (FastMCP only) ----------------------------------------
cat > "$MCP_DIR/requirements.txt" << 'REQ'
fastmcp>=2.10,<3
REQ

# ---- start.sh (bootstrap venv quietly, then run server) ----------------------
cat > "$MCP_DIR/start.sh" << 'SH'
#!/usr/bin/env bash
set -euo pipefail

# IMPORTANT: keep stdout clean until the server starts.
# Route bootstrap noise to stderr and disable pip version check.
exec 3>&1          # keep a dup of stdout just in case
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PYTHONWARNINGS="ignore"

WS="${CODEUSE_WORKSPACE:-$PWD}"
VENV="$WS/.mcp/.venv"

# Pick a Python
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

# From here on, switch back to real stdout and exec the server.
exec "$VENV/bin/python" -u "$WS/.mcp/agent/server.py"
SH
chmod +x "$MCP_DIR/start.sh"

# ---- .vscode/mcp.json (runs in the *container* via stdio) --------------------
# Backup existing file if present and different.
if [ -f "$MCP_JSON" ]; then
  if ! grep -q '"codeuse"' "$MCP_JSON"; then
    cp -n "$MCP_JSON" "$MCP_JSON.bak"
  fi
fi

cat > "$MCP_JSON" << 'JSON'
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

# ---- helpful ignore (optional) ----------------------------------------------
if [ -f .gitignore ] && ! grep -q '^\.mcp/\.venv$' .gitignore; then
  printf "\n# MCP server venv\n.mcp/.venv\n" >> .gitignore
fi

echo "✅ Added/updated MCP server files:"
echo "   - $MCP_DIR/server.py"
echo "   - $MCP_DIR/start.sh"
echo "   - $MCP_DIR/requirements.txt"
echo "   - $MCP_JSON"
echo
echo "Next steps:"
echo "  1) Remove the old venv: rm -rf .mcp/.venv"
echo "  2) Reopen in container (Dev Containers: Rebuild/Reload)."
echo "  3) In Copilot: Tools → start 'codeuse'."
echo "  4) Try:"
echo "     • #env_summary"
echo "     • open env://summary"
echo "     • #run_commands cmds:'[\"latexmk -pdf -interaction=nonstopmode -file-line-error examples/tikz-main.tex\"]'"
echo "     • #sh_exec cmd:\"latexmk -pdf examples/tikz-main.tex\""



# ---- optional: emit a devcontainer.json merge snippet ------------------------
# DC_DIR=".devcontainer"
# DC_FILE="$DC_DIR/devcontainer.json"
# SNIPPET="$DC_DIR/devcontainer.mcp.jsonc"

# mkdir -p "$DC_DIR"

# cat > "$SNIPPET" << 'JSONC'
# /*
#  Paste this under:  customizations → vscode → mcp → servers

#  Example (merge into your existing "customizations.vscode" block):
#  {
#    "customizations": {
#      "vscode": {
#        // ... your existing extensions/settings ...
#        "mcp": {
#          "servers": {
#            "codeuse": {
#              "type": "stdio",
#              "command": "bash",
#              "args": ["-lc", "exec \"$CODEUSE_WORKSPACE/.mcp/agent/start.sh\""],
#              "env": {
#                // Use the container-scoped workspace variable here:
#                "CODEUSE_WORKSPACE": "${containerWorkspaceFolder}"
#              }
#            }
#          }
#        }
#      }
#    }
#  }
# */
# JSONC

# echo
# echo "ℹ️  Optional wiring for Codespaces/devcontainers:"
# if [ -f "$DC_FILE" ]; then
#   echo "   • Created $SNIPPET with a merge-ready MCP block."
#   echo "   • Open $DC_FILE and paste the block under customizations.vscode.mcp.servers."
# else
#   echo "   • No $DC_FILE found; created $SNIPPET with the block you can copy into a future devcontainer.json."
# fi
