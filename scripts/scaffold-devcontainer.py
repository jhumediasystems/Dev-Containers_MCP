#!/usr/bin/env python3
"""Generate devcontainer scaffolding via an LLM.

The script prompts a language model to emit a `.devcontainer` directory
containing `devcontainer.json`, `Dockerfile`, and `onCreate.sh`. Pass a
`containerdescription-prompt.md` file describing the environment or run the
script without arguments to enter the description interactively. The model is
expected to search the web for authoritative base images and VS Code extensions.
An OpenAI-compatible API key must be supplied in the `OPENAI_API_KEY`
environment variable.
"""
import json
import os
import pathlib
import re
import shutil
import subprocess
import sys
import urllib.request
import argparse

MODEL = os.environ.get("OPENAI_MODEL", "gpt-5")
API_KEY = os.environ.get("OPENAI_API_KEY")
API_URL = os.environ.get("OPENAI_API_URL", "https://api.openai.com/v1/chat/completions")

SYSTEM_PROMPT = (
    "You generate development container scaffolding. Given a description, search "
    "the web for widely used base images, authoritative docs, and popular VS Code "
    "extensions. Reply with a JSON object containing keys 'devcontainer', "
    "'dockerfile', and 'onCreate'. 'devcontainer' must be a valid devcontainer.json "
    "object, 'dockerfile' is the Dockerfile contents, and 'onCreate' is a shell "
    "script. Infer sensible bound volumes and exposed ports for the use case. "
    "Use images from ghcr.io/devcontainers when possible and list required packages."
)

def chat(prompt: str) -> str:
    if not API_KEY:
        raise RuntimeError("OPENAI_API_KEY is not set")
    payload = {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        "response_format": {"type": "json_object"},
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        API_URL, data=data, headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}",
        }
    )
    with urllib.request.urlopen(req) as resp:
        resp_data = json.load(resp)
    return resp_data["choices"][0]["message"]["content"]


def build_prompt(desc: str, dev_dir_path: str = ".devcontainer") -> str:
    """Include existing configs in the prompt if present.

    dev_dir_path: directory containing devcontainer files to update (default='.devcontainer').
    """
    dev_dir = pathlib.Path(dev_dir_path)
    if not dev_dir.is_dir():
        return desc
    parts = []
    for name in ["devcontainer.json", "Dockerfile", "onCreate.sh"]:
        path = dev_dir / name
        if path.exists():
            parts.append(f"Existing {name}:\n{path.read_text(encoding='utf-8')}")
    parts.append("Update these configs based on the following description:\n" + desc)
    return "\n\n".join(parts)


def parse_base_image(dockerfile_text: str) -> str | None:
    for line in dockerfile_text.splitlines():
        line = line.strip()
        if line.startswith("FROM"):
            parts = line.split()
            if len(parts) >= 2:
                return parts[1]
    return None


APT_INSTALL_RE = re.compile(r"apt-get\s+install\s+(-y\s+)?(?P<pkgs>[^&]+)")


def find_packages(dockerfile_text: str) -> list[str]:
    pkgs: list[str] = []
    for line in dockerfile_text.splitlines():
        match = APT_INSTALL_RE.search(line)
        if match:
            pkgs.extend(
                [p for p in re.split(r"\s+", match.group("pkgs").strip()) if p and not p.startswith("-")]
            )
    return pkgs


def validate_base_image(image: str) -> None:
    if not shutil.which("docker"):
        print("docker not installed; skipping base image validation", file=sys.stderr)
        return
    result = subprocess.run(
        ["docker", "manifest", "inspect", image],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    if result.returncode != 0:
        print(f"Base image {image} not found", file=sys.stderr)


def validate_packages(image: str, packages: list[str]) -> None:
    if not packages:
        return
    if not shutil.which("docker"):
        print("docker not installed; skipping package validation", file=sys.stderr)
        return
    # Run apt-get update once before checking packages
    update_cmd = [
        "docker",
        "run",
        "--rm",
        image,
        "apt-get",
        "update",
    ]
    subprocess.run(update_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for pkg in packages:
        cmd = [
            "docker",
            "run",
            "--rm",
            image,
            "apt-cache",
            "show",
            pkg,
        ]
        if subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
            print(f"Package {pkg} not available in {image}", file=sys.stderr)

def main() -> None:
    parser = argparse.ArgumentParser(description="Generate or update a devcontainer using an LLM")
    parser.add_argument("prompt_file", nargs="?", help="Path to containerdescription-prompt.md; if omitted, prompt interactively")
    parser.add_argument("--devcontainer-dir", "-d", default=".devcontainer", help="Directory to write devcontainer files (default: .devcontainer)")
    args = parser.parse_args()

    if args.prompt_file and pathlib.Path(args.prompt_file).is_file():
        desc = pathlib.Path(args.prompt_file).read_text(encoding="utf-8")
    elif not args.prompt_file:
        desc = input("Describe the environment to scaffold: ")
    else:
        print(f"Prompt file not found: {args.prompt_file}", file=sys.stderr)
        sys.exit(1)

    prompt = build_prompt(desc, args.devcontainer_dir)
    content = chat(prompt)
    try:
        files = json.loads(content)
    except json.JSONDecodeError as exc:
        print("Model did not return valid JSON:", exc, file=sys.stderr)
        sys.exit(1)

    dev_dir = pathlib.Path(args.devcontainer_dir)
    dev_dir.mkdir(exist_ok=True)
    (dev_dir / "devcontainer.json").write_text(
        json.dumps(files.get("devcontainer", {}), indent=2), encoding="utf-8"
    )
    (dev_dir / "Dockerfile").write_text(files.get("dockerfile", ""), encoding="utf-8")
    (dev_dir / "onCreate.sh").write_text(files.get("onCreate", ""), encoding="utf-8")

    dockerfile_text = files.get("dockerfile", "")
    image = parse_base_image(dockerfile_text)
    if image:
        validate_base_image(image)
        validate_packages(image, find_packages(dockerfile_text))

    print("Wrote scaffolding to .devcontainer/", file=sys.stderr)

if __name__ == "__main__":
    main()
