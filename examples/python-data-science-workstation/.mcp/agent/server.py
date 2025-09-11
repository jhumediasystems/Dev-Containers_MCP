#!/usr/bin/env python3
import os, json, subprocess, shutil, platform
from pathlib import Path
from typing import Optional
from fastmcp import FastMCP

mcp = FastMCP("python-data-science-workstation-agent")

ROOT = Path(os.environ.get("CODEUSE_WORKSPACE", os.getcwd())).resolve()
TOOLS_FILE = ROOT / ".mcp" / "agent" / "tools.json"
STATE_DIR = ROOT / ".mcp" / "state"
STATE_DIR.mkdir(parents=True, exist_ok=True)
ENV_SUMMARY_FILE = STATE_DIR / "env-summary.json"
VENV_PATH = "/home/vscode/.venv/ds"

def _safe_join(p: Optional[str]) -> Path:
    path = (ROOT / (p or ".")).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Path escapes workspace")
    return path

def _which(name: str) -> str:
    return shutil.which(name) or ""

def _cmd_version(cmd: str, venv: bool = False) -> str:
    try:
        if venv:
            cmd = f"source {VENV_PATH}/bin/activate && {cmd}"
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
            "python": _which("python3"),
            "pip": _which("pip3"),
            "jupyter": f"{VENV_PATH}/bin/jupyter" if Path(f"{VENV_PATH}/bin/jupyter").exists() else "",
            "black": f"{VENV_PATH}/bin/black" if Path(f"{VENV_PATH}/bin/black").exists() else "",
            "isort": f"{VENV_PATH}/bin/isort" if Path(f"{VENV_PATH}/bin/isort").exists() else "",
            "flake8": f"{VENV_PATH}/bin/flake8" if Path(f"{VENV_PATH}/bin/flake8").exists() else "",
            "pytest": f"{VENV_PATH}/bin/pytest" if Path(f"{VENV_PATH}/bin/pytest").exists() else "",
        },
        "versions": {
            "python": _cmd_version("python --version", venv=True),
            "pip": _cmd_version("pip --version", venv=True),
            "numpy": _cmd_version("python -c 'import numpy; print(numpy.__version__)'", venv=True),
            "pandas": _cmd_version("python -c 'import pandas; print(pandas.__version__)'", venv=True),
            "jupyter": _cmd_version("jupyter --version", venv=True),
        },
        "virtual_env": {
            "path": VENV_PATH,
            "active": Path(f"{VENV_PATH}/bin/python").exists(),
        },
        "jupyter_config": {
            "kernels_available": _cmd_version("jupyter kernelspec list", venv=True),
        },
        "tools": _load_tools(),
    }

@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    """Get a summary of the Python data science environment including installed packages and Jupyter setup."""
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _generate_env_summary()
        ENV_SUMMARY_FILE.write_text(json.dumps(data, indent=2), encoding="utf-8")
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)

@mcp.tool(name="run_commands")
def run_commands(cmds: list[str], cwd: str = ".", stop_on_error: bool = True, timeout_sec: int = 300, use_venv: bool = True) -> str:
    """Run shell commands in the workspace. Set use_venv=True to run in the data science virtual environment."""
    workdir = _safe_join(cwd)
    lines = []
    for cmd in cmds:
        if use_venv:
            cmd = f"source {VENV_PATH}/bin/activate && {cmd}"
        proc = subprocess.run([
            "/bin/bash", "-lc", cmd
        ], cwd=workdir, text=True, capture_output=True, timeout=timeout_sec)
        lines.append(f"$ {cmd}\n{proc.stdout}{proc.stderr}")
        if stop_on_error and proc.returncode != 0:
            break
    return "\n".join(lines)

@mcp.tool(name="pip_install")
def pip_install(packages: list[str], cwd: str = ".") -> str:
    """Install Python packages using pip in the data science virtual environment."""
    workdir = _safe_join(cwd)
    cmd = f"source {VENV_PATH}/bin/activate && pip install " + " ".join(packages)
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=600)
    return f"$ pip install {' '.join(packages)}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="pip_list")
def pip_list(cwd: str = ".") -> str:
    """List installed packages in the data science virtual environment."""
    workdir = _safe_join(cwd)
    cmd = f"source {VENV_PATH}/bin/activate && pip list"
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ pip list\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="start_jupyter_lab")
def start_jupyter_lab(port: int = 8888, cwd: str = ".") -> str:
    """Start Jupyter Lab server. Returns command to run (use run_commands for actual execution)."""
    workdir = _safe_join(cwd)
    return f"cd {workdir} && source {VENV_PATH}/bin/activate && jupyter lab --port={port} --ip=0.0.0.0 --no-browser --allow-root"

@mcp.tool(name="jupyter_kernels")
def jupyter_kernels(cwd: str = ".") -> str:
    """List available Jupyter kernels."""
    workdir = _safe_join(cwd)
    cmd = f"source {VENV_PATH}/bin/activate && jupyter kernelspec list"
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ jupyter kernelspec list\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="format_python_code")
def format_python_code(file_path: str, cwd: str = ".") -> str:
    """Format Python code using Black."""
    workdir = _safe_join(cwd)
    file_full_path = workdir / file_path
    if not file_full_path.exists():
        return f"Error: File {file_path} not found"
    
    cmd = f"source {VENV_PATH}/bin/activate && black {file_path}"
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ black {file_path}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="sort_imports")
def sort_imports(file_path: str, cwd: str = ".") -> str:
    """Sort Python imports using isort."""
    workdir = _safe_join(cwd)
    file_full_path = workdir / file_path
    if not file_full_path.exists():
        return f"Error: File {file_path} not found"
    
    cmd = f"source {VENV_PATH}/bin/activate && isort {file_path}"
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ isort {file_path}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="lint_python_code")
def lint_python_code(file_path: str, cwd: str = ".") -> str:
    """Lint Python code using flake8."""
    workdir = _safe_join(cwd)
    file_full_path = workdir / file_path
    if not file_full_path.exists():
        return f"Error: File {file_path} not found"
    
    cmd = f"source {VENV_PATH}/bin/activate && flake8 {file_path}"
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=60)
    return f"$ flake8 {file_path}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="run_python_script")
def run_python_script(script_path: str, args: list[str] = None, cwd: str = ".") -> str:
    """Run a Python script in the data science virtual environment."""
    workdir = _safe_join(cwd)
    script_full_path = workdir / script_path
    if not script_full_path.exists():
        return f"Error: Script {script_path} not found"
    
    cmd_args = " ".join(args) if args else ""
    cmd = f"source {VENV_PATH}/bin/activate && python {script_path} {cmd_args}".strip()
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {cmd}\n{proc.stdout}{proc.stderr}"

@mcp.tool(name="run_tests")
def run_tests(test_path: str = "tests/", verbose: bool = False, cwd: str = ".") -> str:
    """Run tests using pytest."""
    workdir = _safe_join(cwd)
    cmd = f"source {VENV_PATH}/bin/activate && pytest"
    if verbose:
        cmd += " -v"
    cmd += f" {test_path}"
    
    proc = subprocess.run([
        "/bin/bash", "-lc", cmd
    ], cwd=workdir, text=True, capture_output=True, timeout=300)
    return f"$ {cmd}\n{proc.stdout}{proc.stderr}"

if __name__ == "__main__":
    mcp.run()