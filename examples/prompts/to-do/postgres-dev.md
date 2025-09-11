Goal: Postgres development workstation with psql client, a local postgres service, and migration tooling.

Requirements:
- Base on `ghcr.io/devcontainers/images/base` with `docker-compose.yml` for a postgres:16 service.
- Tools: psql (postgresql-client), golang-migrate CLI (or dbmate), jq.
- VS Code extensions: ms-ossdata.vscode-postgresql.
- onCreate.sh: wait for service, run a basic healthcheck, apply migrations if `migrations/` exists.

