ARG GO_VARIANT=1.21-bookworm
# Using MCR mirror of devcontainers image to avoid ghcr registry access issues
FROM mcr.microsoft.com/devcontainers/go:1-${GO_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Useful OS deps for Go development
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential \
 && rm -rf /var/lib/apt/lists/*

# Switch back to vscode user
USER vscode

# Install Go tools that will be used by onCreate.sh
# Note: We let onCreate.sh handle the actual tool installation to ensure 
# they're installed with the correct Go version and GOPATH