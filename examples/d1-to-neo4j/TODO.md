# TODO – D1 to Neo4j Workstation

- [ ] Wire conversion script entrypoints once `resources/d1-to-neo4j` is populated (update `scripts/convert-d1-dump.sh` accordingly).
- [ ] Add automated smoke test (GitHub Actions) to export a sample D1 DB, run the converter, and validate Neo4j ingest commands.
- [ ] Evaluate mounting Neo4j logs to `neo4j-logs/` for easier inspection.
- [ ] Optionally add Bloom or Graph Data Science tooling via plugins if required by workflows.
- [ ] Extend MCP server with canned Cypher queries for common analyses (e.g., degree centrality, cluster detection).
