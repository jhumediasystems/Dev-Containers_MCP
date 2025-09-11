ARG PYTHON_VARIANT=3.11-bookworm
FROM mcr.microsoft.com/devcontainers/python:1-${PYTHON_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    jq curl sqlite3 \
 && rm -rf /var/lib/apt/lists/*

# Optional: keep workdir consistent with devcontainers default
WORKDIR /workspaces

USER vscode

