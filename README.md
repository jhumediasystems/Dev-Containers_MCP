# Development Environment Templates with MCP

This repository experiments with a repeatable workflow for building custom development environments that work in VS Code Dev Containers, GitHub Codespaces and other Docker‑based setups. Each environment is described by a `Dockerfile` and `.devcontainer` configuration and is paired with a lightweight Model Context Protocol (MCP) server that exposes the container's tools and common commands to a coding agent.

## Why

Current coding agents start from generic images and must bootstrap their tools on every run.  By baking the toolchain into a container and generating an MCP server that knows how to operate inside it, we can provide agents with rich, ready‑to‑use environments that are easy to share and reproduce.

## Repository layout

- `examples/` – self‑contained sample environments. The first example, `latex-workstation`, contains the original LaTeX setup; `cloudflare-workstation` adds Cloudflare Workers local dev + deploy flows.
- `scripts/` – utility scripts including `add-mcp-to-devcontainer.sh` for MCP scaffolding and `scaffold-devcontainer.py` for LLM‑driven environment setup with image and package validation.
- `README.md` (this file) – project goals and high level design.
- `TODO.md` – planned work to generalize the approach.

## Vision

The long term goal is to turn this into a generator for new environments:

1. Start from an existing image (e.g. from [devcontainers/images](https://github.com/devcontainers/images)).
2. Generate or amend a `.devcontainer` + `Dockerfile` with necessary tools.
3. Produce an MCP server that enumerates those tools and exposes common commands.
4. Ship the result as an easily deployable template for Codespaces or any Docker host.

The `latex-workstation` and `cloudflare-workstation` examples prove the concept; upcoming work will broaden the project to cover diverse stacks such as web development, cloud management and command‑line workflows.

## Getting started

Explore the LaTeX example under `examples/latex-workstation` to see how the pieces fit together.  New examples and automation scripts will appear as the project evolves.  The `scripts/add-mcp-to-devcontainer.sh` utility can scaffold a basic MCP server from a devcontainer definition, while `scripts/scaffold-devcontainer.py` can generate or amend a devcontainer setup from a brief description and verify that the base image and requested packages are available.

Copy `.env.example` to `.env` and provide an `OPENAI_API_KEY` before running the scaffolding script. Supply an environment description interactively or pass a `containerdescription-prompt.md` file such as `examples/containerdescription-prompt.md`.

## Container Factory (top-level devcontainer)

Open the repository in the included devcontainer (`.devcontainer/`). This "container‑constructing factory" gives you a ready Python environment and the scripts to generate new devcontainers and their MCP servers.

On create, it auto‑generates an MCP server stub for the current repo using `scripts/add-mcp-to-devcontainer.sh`. The server summarizes installed tools and can run commands inside the container.

## Standard workflow

1. Author a prompt describing the desired environment (or use `examples/containerdescription-prompt.md`).
2. Run the scaffolder to (re)generate a devcontainer in any target directory:

   `python scripts/scaffold-devcontainer.py -d <target> [containerdescription-prompt.md]`

   - It asks the LLM to propose a Dockerfile, devcontainer.json, onCreate.sh, and sensible VS Code extensions.
   - It optionally validates the proposed base image and apt packages using Docker, when available.

3. Generate an MCP server tailored to that devcontainer:

   `bash scripts/add-mcp-to-devcontainer.sh <target> <target>/Dockerfile`

   - Parses the Dockerfile for apt/pip installs and the devcontainer.json for features.
   - Emits `.mcp/agent/` with a `fastmcp` server exposing tools like `env_summary` and `run_commands`.
   - Adds `.vscode/mcp.json` so the server is discoverable in Codespaces/Dev Containers.

4. Open the target in a container and iterate. Use the MCP server from the Command Palette (“List MCP servers”) to query the environment and run common commands.

## Notes on applicability

- `scripts/scaffold-devcontainer.py` is general‑purpose and can target any path via `--devcontainer-dir`. It incorporates existing configs into the prompt so the LLM updates rather than overwrites blindly.
- `scripts/add-mcp-to-devcontainer.sh` is environment‑agnostic. It infers tools from your Dockerfile and devcontainer features, and it self‑boots a private venv in `.mcp/.venv` when first launched.

## Next steps

Open this repo in its devcontainer, set your `.env` (OPENAI_API_KEY), and ask your coding agent to propose a TODO list of candidate development environments to scaffold. Then iterate: for each environment, run the scaffolder and MCP generator, cross‑check against authoritative images/docs, and refine.
