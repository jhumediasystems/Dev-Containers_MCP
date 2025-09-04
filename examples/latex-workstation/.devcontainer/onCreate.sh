#!/usr/bin/env bash
set -euo pipefail

# This is safe to rerun in Codespaces/Dev Containers and keeps the image healthy after rebuilds.

# Ensure MiKTeX is in a clean, up-to-date state and auto-install is enabled.
sudo miktexsetup --shared=yes finish || true
sudo initexmf --admin --set-config-value [MPM]AutoInstall=1 || true
sudo mpm --admin --update-db || true
sudo mpm --admin --update || true

# Build font cache (harmless if already built)
sudo fc-cache -f -v || true

echo "onCreate complete."

