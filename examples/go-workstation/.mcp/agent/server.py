#!/usr/bin/env python3
import os, json, subprocess, shutil, platform
from pathlib import Path
from typing import Optional
from fastmcp import FastMCP

mcp = FastMCP("go-workstation-agent")

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
            "go": _which("go"),
            "staticcheck": _which("staticcheck"),
            "golangci-lint": _which("golangci-lint"),
            "goreleaser": _which("goreleaser"),
            "git": _which("git"),
        },
        "versions": {
            "go": _cmd_version("go version"),
            "staticcheck": _cmd_version("staticcheck -version"),
            "golangci-lint": _cmd_version("golangci-lint --version"),
            "goreleaser": _cmd_version("goreleaser --version"),
        },
        "go_env": {
            "GOROOT": _cmd_version("go env GOROOT"),
            "GOPATH": _cmd_version("go env GOPATH"),
            "GOOS": _cmd_version("go env GOOS"),
            "GOARCH": _cmd_version("go env GOARCH"),
        },
        "tools": _load_tools(),
    }

@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    """Get a summary of the Go development environment including installed tools and versions."""
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _generate_env_summary()
        ENV_SUMMARY_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)

@mcp.tool(name="run_commands")
def run_commands(cmds: list[str], cwd: str = ".", stop_on_error: bool = True, timeout_sec: int = 300) -> str:
    """Run shell commands in the workspace. Useful for Go development tasks."""
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

@mcp.tool(name="go_mod_init")
def go_mod_init(module_name: str, cwd: str = ".") -> str:
    """Initialize a new Go module with the specified name."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "go", "mod", "init", module_name
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ go mod init {module_name}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="go_test")
def go_test(package: str = "./...", verbose: bool = False, cwd: str = ".") -> str:
    """Run Go tests for the specified package(s)."""
    workdir = _safe_join(cwd)
    cmd = ["go", "test"]
    if verbose:
        cmd.append("-v")
    cmd.append(package)
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="go_build")
def go_build(output: str = "", package: str = ".", cwd: str = ".") -> str:
    """Build the Go package."""
    workdir = _safe_join(cwd)
    cmd = ["go", "build"]
    if output:
        cmd.extend(["-o", output])
    cmd.append(package)
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="staticcheck")
def staticcheck(package: str = "./...", cwd: str = ".") -> str:
    """Run staticcheck static analysis on the specified package(s)."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "staticcheck", package
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ staticcheck {package}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="golangci_lint")
def golangci_lint(action: str = "run", cwd: str = ".") -> str:
    """Run golangci-lint with the specified action."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "golangci-lint", action
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ golangci-lint {action}\n{proc.stdout}{proc.stderr}"

if __name__ == "__main__":
    mcp.run()