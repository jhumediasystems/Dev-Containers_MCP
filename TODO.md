# Next steps

1. **General MCP generator**
   - Expand `scripts/add-mcp-to-devcontainer.sh` into a generic tool that reads a `.devcontainer` + `Dockerfile` and emits an MCP server exposing installed tools and common commands.
   - Support most images from [devcontainers/images](https://github.com/devcontainers/images) and other GHCR/Docker Hub bases.
2. **Environment scaffolding**
   - Scripted prompts to an LLM that create or amend a `.devcontainer`, `onCreate.sh`, and `Dockerfile` from user input.
   - Auto‑locate base images and package installs based on structured prompts.
3. **Additional examples**
   - Produce templates for stacks such as LEMP, Python web apps, S3/cloud tooling, and Cloudflare workers with local D1/R2 stores.
   - Each example should include an MCP server definition and usage notes.
4. **Documentation & guidelines**
   - Document how to generate a new environment and integrate the MCP server with common coding agents.
   - Describe conventions for exposing shell commands and environment variables.
5. **Automation & CI**
   - Add scripts or workflows that build containers and validate MCP generation in CI.
   - Consider lightweight tests that exercise common commands in each example.
