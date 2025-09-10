#!/usr/bin/env bash
set -euo pipefail

# Render wrangler.toml from wrangler.toml.template using variables from .env

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKER_DIR="$ROOT_DIR/workers/deploy/wrangler-cli_test"
TEMPLATE="$WORKER_DIR/wrangler.toml.template"
OUTFILE="$WORKER_DIR/wrangler.toml"

if [[ ! -f "$ROOT_DIR/.env" ]]; then
  echo "No .env found in $ROOT_DIR. Copy .env.example to .env and fill values." >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$ROOT_DIR/.env"

GREETING_VAL=${GREETING:-Hello from Cloudflare Workers}
D1_NAME=${D1_DATABASE_NAME:-localdb}
R2_NAME=${R2_BUCKET_NAME:-local-bucket}
KV_ID=${KV_NAMESPACE_ID:-00000000000000000000000000000000}

mkdir -p "$WORKER_DIR"
sed \
  -e "s/__GREETING__/${GREETING_VAL//\//\/}/g" \
  -e "s/__D1_DATABASE_NAME__/${D1_NAME//\//\/}/g" \
  -e "s/__R2_BUCKET_NAME__/${R2_NAME//\//\/}/g" \
  -e "s/__KV_NAMESPACE_ID__/${KV_ID//\//\/}/g" \
  "$TEMPLATE" > "$OUTFILE"

echo "Wrote $OUTFILE from $TEMPLATE using .env"

