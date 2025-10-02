#!/usr/bin/env python3
import json
import os
import platform
import shutil
import subprocess
from pathlib import Path
from typing import Optional

from fastmcp import FastMCP

mcp = FastMCP("d1-to-neo4j-agent")

ROOT = Path(os.environ.get("CODEUSE_WORKSPACE", os.getcwd())).resolve()
TOOLS_FILE = ROOT / ".mcp" / "agent" / "tools.json"
STATE_DIR = ROOT / ".mcp" / "state"
STATE_DIR.mkdir(parents=True, exist_ok=True)
ENV_SUMMARY_FILE = STATE_DIR / "env-summary.json"

PY_ENV = ROOT / ".venv" / "d1neo4j"
SCRIPTS_DIR = ROOT / "scripts"
NEO4J_DATA_DIR = ROOT / "data" / "neo4j"


def _safe_join(relative: Optional[str]) -> Path:
    path = (ROOT / (relative or ".")).resolve()
    if path != ROOT and ROOT not in path.parents:
        raise ValueError("Path escapes workspace")
    return path


def _which(name: str) -> str:
    return shutil.which(name) or ""


def _cmd_output(cmd: list[str], cwd: Optional[Path] = None, input_text: Optional[str] = None, timeout: int = 60) -> str:
    try:
        proc = subprocess.run(cmd, cwd=cwd, input=input_text, text=True, capture_output=True, timeout=timeout)
    except FileNotFoundError:
        return "not-installed"
    except subprocess.TimeoutExpired:
        return "timeout"
    if proc.returncode != 0:
        return (proc.stderr or proc.stdout or str(proc.returncode)).strip()
    return (proc.stdout or proc.stderr or "").strip()


def _load_tools() -> dict:
    if TOOLS_FILE.exists():
        try:
            return json.loads(TOOLS_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            return {"error": "tools.json unreadable"}
    return {}


def _env_summary() -> dict:
    node_version = _cmd_output(["node", "-v"]).lstrip("v")
    summary = {
        "workspace": str(ROOT),
        "os": {
            "platform": platform.system(),
            "release": platform.release(),
        },
        "paths": {
            "node": _which("node"),
            "npm": _which("npm"),
            "wrangler": _which("wrangler"),
            "python": _which("python3"),
            "pip": _which("pip3"),
            "java": _which("java"),
            "neo4j": _which("neo4j"),
            "cypher-shell": _which("cypher-shell"),
        },
        "versions": {
            "node": node_version,
            "npm": _cmd_output(["npm", "-v"]),
            "wrangler": _cmd_output(["wrangler", "--version"]),
            "python": _cmd_output(["python3", "--version"]),
            "pip": _cmd_output(["pip3", "--version"]),
            "java": _cmd_output(["java", "-version"]),
            "neo4j": _cmd_output(["neo4j", "--version"]),
            "cypher-shell": _cmd_output(["cypher-shell", "--version"]),
        },
        "neo4j": {
            "data_dir": str(NEO4J_DATA_DIR),
            "running": "http" in _cmd_output(["curl", "-I", "http://localhost:7474"], timeout=5).lower(),
            "ports": {
                "http": 7474,
                "bolt": 7687,
            },
        },
        "python_virtualenv": {
            "path": str(PY_ENV),
            "exists": PY_ENV.exists(),
        },
        "tools": _load_tools(),
    }
    ENV_SUMMARY_FILE.write_text(json.dumps(summary, indent=2), encoding="utf-8")
    return summary


@mcp.tool(name="env_summary")
def env_summary(refresh: bool = False, pretty: bool = True) -> str:
    """Return a cached environment summary (set refresh=True to regenerate)."""
    if refresh or not ENV_SUMMARY_FILE.exists():
        data = _env_summary()
    else:
        data = json.loads(ENV_SUMMARY_FILE.read_text(encoding="utf-8"))
    return json.dumps(data, indent=2 if pretty else None)


@mcp.tool(name="run_commands")
def run_commands(commands: list[str], cwd: str = ".", use_python_env: bool = False, stop_on_error: bool = True, timeout_sec: int = 300) -> str:
    """Run shell commands inside the workspace. Set use_python_env=True to activate .venv/d1neo4j."""
    workdir = _safe_join(cwd)
    lines: list[str] = []
    for cmd in commands:
        final_cmd = cmd
        if use_python_env and PY_ENV.exists():
            final_cmd = f"source {PY_ENV}/bin/activate && {cmd}"
        proc = subprocess.run(["/bin/bash", "-lc", final_cmd], cwd=workdir, text=True, capture_output=True, timeout=timeout_sec)
        lines.append(f"$ {final_cmd}\n{proc.stdout}{proc.stderr}")
        if stop_on_error and proc.returncode != 0:
            break
    return "\n".join(lines)


def _background_process(command: str, log_file: Path) -> str:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.Popen(["/bin/bash", "-lc", f"{command} >> {log_file} 2>&1 & echo $!"], cwd=ROOT, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    pid = proc.stdout.readline().strip() if proc.stdout else ""
    return f"started; pid={pid}; logs={log_file}"


@mcp.tool(name="start_neo4j")
def start_neo4j(background: bool = True) -> str:
    """Start Neo4j using scripts/start-neo4j-console.sh. background=True detaches into logs/neo4j-console.log."""
    script = SCRIPTS_DIR / "start-neo4j-console.sh"
    if not script.exists():
        return "Missing scripts/start-neo4j-console.sh"
    cmd = f"bash {script}"
    if background:
        log_file = ROOT / "neo4j-logs" / "console.log"
        return _background_process(cmd, log_file)
    proc = subprocess.run(["/bin/bash", "-lc", cmd], cwd=ROOT, text=True, capture_output=True)
    return f"$ {cmd}\n{proc.stdout}{proc.stderr}"


@mcp.tool(name="stop_neo4j")
def stop_neo4j() -> str:
    """Attempt to stop Neo4j gracefully via sudo neo4j stop."""
    proc = subprocess.run(["/bin/bash", "-lc", "sudo neo4j stop"], cwd=ROOT, text=True, capture_output=True)
    output = proc.stdout + proc.stderr
    return output or "neo4j stop command issued"


@mcp.tool(name="cypher_query")
def cypher_query(query: str, database: str = "neo4j", uri: Optional[str] = None, user: Optional[str] = None, password: Optional[str] = None) -> str:
    """Execute a Cypher query using cypher-shell; returns stdout/stderr."""
    env = os.environ.copy()
    uri = uri or env.get("NEO4J_URI", "bolt://localhost:7687")
    user = user or env.get("NEO4J_USER", "neo4j")
    password = password or env.get("NEO4J_PASSWORD", "d1neo4j")
    cmd = [
        "cypher-shell",
        "-a",
        uri,
        "-u",
        user,
        "-p",
        password,
        "--database",
        database,
    ]
    result = _cmd_output(cmd, input_text=query, timeout=120)
    return result


@mcp.tool(name="convert_d1_dump")
def convert_d1_dump(dump_path: str, target_database: str = "neo4j") -> str:
    """Invoke scripts/convert-d1-dump.sh to transform a D1 dump into Neo4j-friendly CSV/ingest steps."""
    script = SCRIPTS_DIR / "convert-d1-dump.sh"
    if not script.exists():
        return "Missing scripts/convert-d1-dump.sh"
    dump_abs = _safe_join(dump_path)
    if not dump_abs.exists():
        return f"Dump not found: {dump_abs}"
    cmd = f"bash {script} '{dump_abs}' '{target_database}'"
    proc = subprocess.run(["/bin/bash", "-lc", cmd], cwd=ROOT, text=True, capture_output=True, timeout=1800)
    return f"$ {cmd}\n{proc.stdout}{proc.stderr}"


@mcp.tool(name="export_d1_database")
def export_d1_database(d1_name: str, output_sql: str = "d1-dump.sql") -> str:
    """Use wrangler to export a D1 database to a SQL file."""
    script = SCRIPTS_DIR / "export-d1-database.sh"
    if not script.exists():
        return "Missing scripts/export-d1-database.sh"
    output_path = ROOT / output_sql
    cmd = f"bash {script} '{d1_name}' '{output_path}'"
    proc = subprocess.run(["/bin/bash", "-lc", cmd], cwd=ROOT, text=True, capture_output=True, timeout=600)
    return f"$ {cmd}\n{proc.stdout}{proc.stderr}"


if __name__ == "__main__":
    mcp.run()
