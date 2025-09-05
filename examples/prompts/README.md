Baseline prompts for scaffolding development containers with `scripts/scaffold-devcontainer.py`.

How to use:
- Pick a prompt file and pass it to the scaffolder with a target directory: `python scripts/scaffold-devcontainer.py -d <target> examples/prompts/<prompt>.md`
- Then generate an MCP server for that target: `bash scripts/add-mcp-to-devcontainer.sh <target> <target>/Dockerfile`

