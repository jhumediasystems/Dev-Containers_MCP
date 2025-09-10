ARG NODE_VARIANT=22-bookworm
# Using MCR mirror of devcontainers image to avoid ghcr registry access issues
FROM mcr.microsoft.com/devcontainers/javascript-node:1-${NODE_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Useful OS deps for local tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git sqlite3 \
 && rm -rf /var/lib/apt/lists/*

# Install Wrangler and Miniflare globally
# Install Wrangler globally (Miniflare v3 CLI deprecated; wrangler embeds dev runtime)
RUN npm install -g wrangler \
 && npm cache clean --force > /dev/null 2>&1 || true

# Keep default user consistent with base image
USER node
