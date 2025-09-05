ARG NODE_VARIANT=22-bookworm
FROM ghcr.io/devcontainers/images/javascript-node:1-${NODE_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Useful OS deps for local tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git sqlite3 \
 && rm -rf /var/lib/apt/lists/*

# Install Wrangler and Miniflare globally
RUN npm install -g wrangler miniflare \
 && npm cache clean --force > /dev/null 2>&1 || true

# Default workdir (devcontainers sets /workspaces/<repo>)
WORKDIR /workspaces

# Keep default user consistent with base image
USER node

