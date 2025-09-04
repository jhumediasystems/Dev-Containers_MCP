# Next steps

1. **General MCP generator** — *completed*
   - `scripts/add-mcp-to-devcontainer.sh` now inspects the project Dockerfile and devcontainer to emit MCP server scaffolding.
   - Fallback JSON handling enables use on images without `jq`.
2. **Environment scaffolding**
   - `scripts/scaffold-devcontainer.py` prompts an LLM to generate or update a `.devcontainer`, `Dockerfile`, and `onCreate.sh`.
   - Supports interactive prompts or reading from a `containerdescription-prompt.md` file and defaults to the `gpt-5` model.
   - TODO: support amending existing configs and validating base image/package availability.
3. **Additional examples**
   - Produce templates for stacks such as LEMP, Python web apps, S3/cloud tooling, and Cloudflare workers with local D1/R2 stores.
   - Each example should include an MCP server definition and usage notes.
4. **Documentation & guidelines**
   - Document how to generate a new environment and integrate the MCP server with common coding agents.
   - Describe conventions for exposing shell commands and environment variables.
5. **Automation & CI**
   - Add scripts or workflows that build containers and validate MCP generation in CI.
   - Consider lightweight tests that exercise common commands in each example.
