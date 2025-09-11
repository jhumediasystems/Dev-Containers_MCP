ARG NODE_VARIANT=20-bookworm
# Using MCR mirror of devcontainers image to avoid ghcr registry access issues
FROM mcr.microsoft.com/devcontainers/javascript-node:1-${NODE_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Useful OS deps for Node.js development
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential \
    # Dependencies for Playwright browser automation
    libnss3-dev libatk-bridge2.0-dev libdrm-dev libxcomposite-dev \
    libxdamage-dev libxrandr-dev libgbm-dev libxss-dev libasound2-dev \
 && rm -rf /var/lib/apt/lists/*

# Enable corepack for package manager management
RUN corepack enable

# Install pnpm globally via npm as fallback
RUN npm install -g pnpm@latest

# Switch back to node user
USER node