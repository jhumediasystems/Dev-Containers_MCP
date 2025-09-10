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

