# TODO: Development Container Templates

This document tracks the progress of creating development container templates based on the prompts in this directory.

## Overview
We need to create 5 new container templates, each with:
- `.devcontainer/` directory with devcontainer.json, Dockerfile, and onCreate.sh
- MCP server configuration in `.mcp/agent/`
- Testing to ensure containers build successfully
- Documentation

## Container Templates to Create

### 1. Go Workstation (go.md)
**Status:** ✅ Completed
**Location:** `examples/go-workstation/`
**Requirements:**
- Base: `ghcr.io/devcontainers/images/go`
- Tools: staticcheck, golangci-lint, goreleaser
- VS Code: golang.go extension
- onCreate: install tools, print go env

**Completed:**
- ✅ Created devcontainer configuration
- ✅ Created Dockerfile with proper base image
- ✅ Created onCreate.sh script that installs Go tools
- ✅ Created MCP server with Go-specific tools
- ✅ Tested container builds successfully
- ✅ Added comprehensive README documentation

### 2. Node.js Full-Stack Workstation (node-fullstack.md)
**Status:** 🔴 Not Started  
**Location:** `examples/node-fullstack-workstation/`
**Requirements:**
- Base: `ghcr.io/devcontainers/images/javascript-node` (Node 20+)
- Tools: pnpm, typescript, vite, playwright, eslint, prettier
- VS Code: eslint, prettier, playwright extensions
- Ports: 5173 (Vite), 3000 (API)

### 3. Python Data Science Workstation (python-data-science.md)
**Status:** 🔴 Not Started
**Location:** `examples/python-data-science-workstation/`
**Requirements:**
- Base: `ghcr.io/devcontainers/images/python` with miniconda
- Tools: mamba/micromamba, numpy, pandas, scipy, matplotlib, seaborn, scikit-learn, jupyterlab
- VS Code: python, jupyter, datawrangler extensions
- Ports: 8888 (Jupyter)

### 4. Cloud-Native Ops/Dev Workstation (cloud-native.md)
**Status:** 🔴 Not Started
**Location:** `examples/cloud-native-workstation/`
**Requirements:**
- Base: `ghcr.io/devcontainers/features/common-utils` + docker-in-docker
- Tools: kubectl, helm, kustomize, kind, terraform, awscli, gcloud, azure-cli
- VS Code: kubernetes-tools, terraform extensions
- Optional: kind cluster creation

### 5. Postgres Development Workstation (postgres-dev.md)
**Status:** 🔴 Not Started
**Location:** `examples/postgres-dev-workstation/`
**Requirements:**
- Base: `ghcr.io/devcontainers/images/base` with docker-compose
- Tools: psql, golang-migrate/dbmate, jq
- VS Code: postgresql extension
- Services: postgres:16 via docker-compose

## Implementation Notes

### Workflow for Each Container:
1. Create directory structure in `examples/`
2. Use `scripts/scaffold-devcontainer.py` if OpenAI API available
3. Manual creation of devcontainer files if needed
4. Run `scripts/add-mcp-to-devcontainer.sh` to generate MCP server
5. Test container builds: `docker build .devcontainer/`
6. Document in README.md
7. Update this TODO with completion status

### Key Files for Each Template:
- `.devcontainer/devcontainer.json` - Container configuration
- `.devcontainer/Dockerfile` - Image definition
- `.devcontainer/onCreate.sh` - Initialization script
- `.mcp/agent/` - MCP server files (auto-generated)
- `README.md` - Documentation
- `docker-compose.yml` - If services needed (postgres)

## Progress Tracking
- Total containers: 5
- Completed: 3
- In progress: 0
- Not started: 2

### Completed Workstations:
1. ✅ Go Workstation - Full development environment with staticcheck, golangci-lint, goreleaser
2. ✅ Node.js Full-Stack Workstation - Complete setup with pnpm, Vite, Playwright, TypeScript
3. ✅ Python Data Science Workstation - Comprehensive data science environment with Jupyter, pandas, scikit-learn

### Next: Cloud-Native Ops/Dev Workstation

Last updated: December 2024