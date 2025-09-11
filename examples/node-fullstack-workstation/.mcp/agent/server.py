#!/usr/bin/env python3
import os, json, subprocess, shutil, platform
from pathlib import Path
from typing import Optional
from fastmcp import FastMCP

mcp = FastMCP("node-fullstack-workstation-agent")

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
            "node": _which("node"),
            "npm": _which("npm"),
            "pnpm": _which("pnpm"),
            "yarn": _which("yarn"),
            "git": _which("git"),
            "typescript": _which("tsc"),
            "eslint": _which("eslint"),
            "prettier": _which("prettier"),
            "playwright": _which("playwright"),
        },
        "versions": {
            "node": _cmd_version("node --version"),
            "npm": _cmd_version("npm --version"),
            "pnpm": _cmd_version("pnpm --version"),
            "typescript": _cmd_version("tsc --version"),
        },
        "project_info": {
            "has_package_json": (ROOT / "package.json").exists(),
            "has_typescript_config": (ROOT / "tsconfig.json").exists(),
            "has_eslint_config": any((ROOT / f).exists() for f in [".eslintrc.js", ".eslintrc.json", ".eslintrc.yml", "eslint.config.js"]),
            "has_prettier_config": any((ROOT / f).exists() for f in [".prettierrc", ".prettierrc.json", ".prettierrc.yml", "prettier.config.js"]),
            "has_playwright_config": (ROOT / "playwright.config.ts").exists() or (ROOT / "playwright.config.js").exists(),
        },
        "tools": _load_tools(),
    }

@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    """Get a summary of the Node.js development environment including installed tools and project configuration."""
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _generate_env_summary()
        ENV_SUMMARY_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)

@mcp.tool(name="run_commands")
def run_commands(cmds: list[str], cwd: str = ".", stop_on_error: bool = True, timeout_sec: int = 300) -> str:
    """Run shell commands in the workspace. Useful for Node.js development tasks."""
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

@mcp.tool(name="pnpm_install")
def pnpm_install(cwd: str = ".") -> str:
    """Install dependencies using pnpm."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "pnpm", "install"
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ pnpm install\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="pnpm_add")
def pnpm_add(packages: list[str], dev: bool = False, cwd: str = ".") -> str:
    """Add packages using pnpm."""
    workdir = _safe_join(cwd)
    cmd = ["pnpm", "add"]
    if dev:
        cmd.append("-D")
    cmd.extend(packages)
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="pnpm_run")
def pnpm_run(script: str, cwd: str = ".") -> str:
    """Run a pnpm script defined in package.json."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "pnpm", "run", script
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ pnpm run {script}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="create_vite_project")
def create_vite_project(project_name: str, template: str = "vanilla", cwd: str = ".") -> str:
    """Create a new Vite project. Common templates: vanilla, vanilla-ts, react, react-ts, vue, vue-ts, svelte, svelte-ts."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "pnpm", "create", "vite@latest", project_name, "--template", template
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ pnpm create vite@latest {project_name} --template {template}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="create_next_project")
def create_next_project(project_name: str, typescript: bool = True, tailwind: bool = False, cwd: str = ".") -> str:
    """Create a new Next.js project."""
    workdir = _safe_join(cwd)
    cmd = ["pnpm", "create", "next-app@latest", project_name]
    if typescript:
        cmd.append("--typescript")
    if tailwind:
        cmd.append("--tailwind")
    cmd.append("--eslint")
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="lint_project")
def lint_project(fix: bool = False, cwd: str = ".") -> str:
    """Run ESLint on the project."""
    workdir = _safe_join(cwd)
    cmd = ["pnpm", "run", "lint"]
    if fix:
        cmd.append("--fix")
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="format_project")
def format_project(cwd: str = ".") -> str:
    """Format the project using Prettier."""
    workdir = _safe_join(cwd)
    proc = subprocess.run([
        "pnpm", "run", "format"
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ pnpm run format\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="run_tests")
def run_tests(watch: bool = False, ui: bool = False, cwd: str = ".") -> str:
    """Run tests using the configured test runner."""
    workdir = _safe_join(cwd)
    cmd = ["pnpm", "run", "test"]
    if watch:
        cmd.append("--watch")
    if ui:
        cmd.append("--ui")
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="playwright_test")
def playwright_test(ui: bool = False, headed: bool = False, cwd: str = ".") -> str:
    """Run Playwright end-to-end tests."""
    workdir = _safe_join(cwd)
    cmd = ["npx", "playwright", "test"]
    if ui:
        cmd.append("--ui")
    if headed:
        cmd.append("--headed")
    
    proc = subprocess.run(cmd, cwd=workdir, text=True, capture_output=True, timeout=600)
    return f"$ {' '.join(cmd)}\n{proc.stdout}{proc.stderr}"

if __name__ == "__main__":
    mcp.run()