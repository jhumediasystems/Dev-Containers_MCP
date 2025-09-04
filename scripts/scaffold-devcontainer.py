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
import sys
import urllib.request

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

def main() -> None:
    if len(sys.argv) == 2 and pathlib.Path(sys.argv[1]).is_file():
        desc = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
    elif len(sys.argv) == 1:
        desc = input("Describe the environment to scaffold: ")
    else:
        print("Usage: scaffold-devcontainer.py [containerdescription-prompt.md]", file=sys.stderr)
        sys.exit(1)

    content = chat(desc)
    try:
        files = json.loads(content)
    except json.JSONDecodeError as exc:
        print("Model did not return valid JSON:", exc, file=sys.stderr)
        sys.exit(1)

    dev_dir = pathlib.Path(".devcontainer")
    dev_dir.mkdir(exist_ok=True)
    (dev_dir / "devcontainer.json").write_text(
        json.dumps(files.get("devcontainer", {}), indent=2), encoding="utf-8"
    )
    (dev_dir / "Dockerfile").write_text(files.get("dockerfile", ""), encoding="utf-8")
    (dev_dir / "onCreate.sh").write_text(files.get("onCreate", ""), encoding="utf-8")

    print("Wrote scaffolding to .devcontainer/", file=sys.stderr)

if __name__ == "__main__":
    main()
