# D1 to Neo4j Workstation

A devcontainer template that combines the Cloudflare Workers toolkit with a full local Neo4j 5 installation for converting Cloudflare D1 exports into graph datasets. Use it to iterate on the conversion scripts stored in `resources/d1-to-neo4j`, validate the generated graph model, and surface the results through Neo4j Browser/Bloom.

## Key capabilities

- Same Node.js base image and tooling as the Cloudflare workstation (`mcr.microsoft.com/devcontainers/javascript-node:1-22-bookworm`, `wrangler` CLI, SQLite utilities).
- Full Neo4j server (5.x) with Bolt and HTTP ports published (7687/7474) and Java 17 runtime preinstalled.
- Persistent graph storage mapped to `examples/d1-to-neo4j/data/neo4j` inside the repository so data survives container rebuilds.
- Optional Python virtual environment (`.venv/d1neo4j`) bootstrapped from `resources/d1-to-neo4j/requirements.txt` for custom ETL tooling.
- Convenience scripts for exporting D1 databases, launching Neo4j, and invoking the conversion workflow.
- An MCP server (`d1-to-neo4j`) exposing environment summaries plus helper tools (`start_neo4j`, `cypher_query`, `convert_d1_dump`, `export_d1_database`).

## Quick start

1. Ensure your conversion repository is cloned into `resources/d1-to-neo4j` (same level as this folder). The onCreate hook will install Python dependencies if a `requirements.txt` is present.
2. Open `examples/d1-to-neo4j` in VS Code Dev Containers or Codespaces.
3. Wait for the build to finish. The onCreate script will:
   - Align Node with the `.nvmrc` version (22.14.0) if `nvm` is available.
   - Link Neo4j's data directory to `data/neo4j`, set the default password to `d1neo4j`, and display tool versions.
   - Create `.venv/d1neo4j` and `pip install -r resources/d1-to-neo4j/requirements.txt` when that file exists.
4. Launch Neo4j:
   ```sh
   bash scripts/start-neo4j-console.sh
   ```
   The helper shifts Neo4j into the foreground; add `&` or use the MCP `start_neo4j` tool to background it. Access Neo4j Browser via http://localhost:7474 and authenticate with `neo4j / d1neo4j`.
5. Export a D1 database (optional):
   ```sh
   CLOUDFLARE_API_TOKEN=... bash scripts/export-d1-database.sh my-d1-db dumps/my-d1.sql
   ```
6. Convert the exported dump:
   ```sh
   bash scripts/convert-d1-dump.sh dumps/my-d1.sql neo4j
   ```
   The wrapper locates a `convert.sh` or `convert.py` entrypoint under `resources/d1-to-neo4j` and runs it (activating `.venv/d1neo4j` if available).
7. Run Cypher migrations:
   ```sh
   cypher-shell -u neo4j -p d1neo4j -f path/to/graph.cypher
   ```
   or trigger via the MCP `cypher_query` tool.

## Neo4j defaults

- **Data path:** `examples/d1-to-neo4j/data/neo4j`
- **Ports:** 7474 (HTTP), 7687 (Bolt)
- **Auth:** `neo4j` / `d1neo4j` (change with `sudo neo4j-admin dbms set-initial-password <new>`)
- **Logs:** if you background via MCP, output is captured in `neo4j-logs/console.log`.

## Cloudflare + Wrangler usage

Wrangler is installed globally just like the Cloudflare workstation. Export helpers expect `CLOUDFLARE_API_TOKEN` (and optionally `CLOUDFLARE_ACCOUNT_ID`) to be set. Use `wrangler login` inside the container if you prefer interactive auth.

Useful commands:
- `wrangler d1 export <DB> --output dumps/d1.sql`
- `wrangler d1 execute <DB> --command 'select count(*) from ...'`
- `sqlite3 dumps/d1.sql '.tables'`

## MCP server tools

After the devcontainer starts, the `d1-to-neo4j` MCP server is listed by the Codex/VS Code MCP picker. Available tools:
- `env_summary` – dump installed versions and Neo4j status.
- `run_commands` – execute arbitrary shell commands (optionally sourcing `.venv/d1neo4j`).
- `start_neo4j` / `stop_neo4j` – manage the Neo4j console process.
- `cypher_query` – execute ad hoc Cypher through `cypher-shell`.
- `convert_d1_dump` – run `scripts/convert-d1-dump.sh`.
- `export_d1_database` – wrap `wrangler d1 export`.

## Recommended workflow

1. Use `scripts/export-d1-database.sh` to grab fresh data (or place SQLite dumps under `resources/d1-to-neo4j/dumps/`).
2. Call `scripts/convert-d1-dump.sh` to produce CSV/Cypher artifacts tailored for Neo4j.
3. Start Neo4j (`scripts/start-neo4j-console.sh &`) and monitor via browser.
4. Load generated artifacts with `cypher-shell` or the Browser's "Data Importer".
5. Explore using Neo4j Browser (http://localhost:7474) or attach Neo4j Bloom/desktop if installed locally (Bolt port 7687).

## Housekeeping

- `reset-dev-env.sh` mirrors the Cloudflare script for refreshing the devcontainer build cache and VS Code server.
- `docker-compose.yml` provides a local run target with the same image and forwarded ports.
- `.env.example` captures Neo4j credentials and optional Cloudflare values; copy to `.env` as needed.
- Add additional helper scripts alongside the provided ones to encapsulate repeatable graph import steps.

## Notes

- The repository does not ship Neo4j desktop GUIs; connect your local Bloom/Browser instance to Bolt if preferred.
- Change the default Neo4j password immediately for shared deployments.
- If your conversion repo uses another runtime (Go, Rust, etc.), adjust `.devcontainer/Dockerfile` and `.mcp/agent/tools.json` accordingly and re-run `scripts/start-neo4j-console.sh` to refresh permissions.

