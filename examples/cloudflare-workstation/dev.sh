#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../workers/deploy/wrangler-cli_test"
exec wrangler dev index.js --port 8787

