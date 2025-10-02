ARG NODE_VARIANT=22-bookworm
# Using MCR mirror of devcontainers image to avoid ghcr registry access issues
FROM mcr.microsoft.com/devcontainers/javascript-node:1-${NODE_VARIANT}

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Core OS deps shared with the Cloudflare workstation plus Java + Neo4j bits
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    gnupg \
    lsb-release \
    openjdk-17-jdk \
    python3 \
    python3-pip \
    python3-venv \
    sqlite3 \
    unzip \
 && rm -rf /var/lib/apt/lists/*

# Add the official Neo4j Debian repository and install server + shell tooling
RUN curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor -o /usr/share/keyrings/neo4j.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable 5" > /etc/apt/sources.list.d/neo4j.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends neo4j cypher-shell \
 && rm -rf /var/lib/apt/lists/*

# Allow the non-root devcontainer user to control the Neo4j installation
RUN usermod -a -G neo4j node \
 && chown -R neo4j:neo4j /var/lib/neo4j /var/log/neo4j \
 && chmod -R 775 /var/lib/neo4j /var/log/neo4j

# Permit remote connections from inside the Codespace / devcontainer network
RUN sed -i 's~#\?dbms.default_listen_address=.*~dbms.default_listen_address=0.0.0.0~' /etc/neo4j/neo4j.conf \
 && sed -i 's~#\?dbms.default_advertised_address=.*~dbms.default_advertised_address=localhost~' /etc/neo4j/neo4j.conf \
 && echo "dbms.security.http_auth_allowlist=0.0.0.0/0" >> /etc/neo4j/neo4j.conf

# Install Wrangler globally (Miniflare v3 CLI deprecated; wrangler embeds dev runtime)
RUN npm install -g wrangler \
 && npm cache clean --force > /dev/null 2>&1 || true

# Keep default user consistent with base image
USER node

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    NEO4J_HOME=/var/lib/neo4j
