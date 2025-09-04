# Development Environment Templates with MCP

This repository experiments with a repeatable workflow for building custom development environments that work in VS Code Dev Containers, GitHub Codespaces and other Docker‑based setups.  Each environment is described by a `Dockerfile` and `.devcontainer` configuration and is paired with a lightweight Model Context Protocol (MCP) server that exposes the container's tools and common commands to a coding agent.

## Why

Current coding agents start from generic images and must bootstrap their tools on every run.  By baking the toolchain into a container and generating an MCP server that knows how to operate inside it, we can provide agents with rich, ready‑to‑use environments that are easy to share and reproduce.

## Repository layout

- `examples/` – self‑contained sample environments.  The first example, `latex-workstation`, contains the original LaTeX setup from which this project grew.
- `README.md` (this file) – project goals and high level design.
- `TODO.md` – planned work to generalize the approach.

## Vision

The long term goal is to turn this into a generator for new environments:

1. Start from an existing image (e.g. from [devcontainers/images](https://github.com/devcontainers/images)).
2. Generate or amend a `.devcontainer` + `Dockerfile` with necessary tools.
3. Produce an MCP server that enumerates those tools and exposes common commands.
4. Ship the result as an easily deployable template for Codespaces or any Docker host.

The `latex-workstation` example proves the concept; upcoming work will broaden the project to cover diverse stacks such as web development, cloud management and command‑line workflows.

## Getting started

Explore the LaTeX example under `examples/latex-workstation` to see how the pieces fit together.  New examples and automation scripts will appear as the project evolves.
