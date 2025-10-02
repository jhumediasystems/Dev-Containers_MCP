#!/usr/bin/env bash
set -euo pipefail

if ! command -v wrangler >/dev/null 2>&1; then
  echo "wrangler CLI not installed" >&2
  exit 1
fi

DB_NAME="${1:-}"
OUTPUT="${2:-d1-dump.sql}"
FLAGS=("--output" "$OUTPUT")

if [ -z "$DB_NAME" ]; then
  echo "Usage: $0 <database-name> [output.sql]" >&2
  exit 1
fi

if [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then
  FLAGS+=("--account-id" "$CLOUDFLARE_ACCOUNT_ID")
fi

set -x
wrangler d1 export "$DB_NAME" "${FLAGS[@]}"
