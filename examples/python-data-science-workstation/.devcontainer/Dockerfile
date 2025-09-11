ARG PYTHON_VARIANT=3.11-bookworm
# Using MCR mirror of devcontainers image to avoid ghcr registry access issues
FROM mcr.microsoft.com/devcontainers/python:1-${PYTHON_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# OS dependencies for data science and numerical computing
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates curl git build-essential \
    # Linear algebra and scientific computing dependencies
    gfortran libopenblas-dev liblapack-dev libssl-dev \
    # Additional utilities for data science
    wget unzip bzip2 graphviz \
 && rm -rf /var/lib/apt/lists/*

# Switch back to vscode user
USER vscode

# Create data science virtual environment (packages will be installed in onCreate.sh)
RUN python3 -m venv /home/vscode/.venv/ds \
 && echo 'source /home/vscode/.venv/ds/bin/activate' >> ~/.bashrc