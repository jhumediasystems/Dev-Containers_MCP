# Base on a popular GHCR image (not Docker Hub) for a web IDE when needed.
FROM ghcr.io/coder/code-server:4.103.1-noble

USER root
ENV DEBIAN_FRONTEND=noninteractive

# --- Base OS deps & fonts (kept fairly lean) ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl wget gnupg2 software-properties-common \
    locales tzdata sudo make git perl python3 python3-pip python3-venv \
    unzip xz-utils tini \
    ghostscript poppler-utils \
    fontconfig fonts-lmodern fonts-texgyre fonts-noto fonts-inconsolata \
    # latexindent perl deps so formatting works out of the box
    libyaml-tiny-perl libfile-homedir-perl liblog-log4perl-perl libunicode-linebreak-perl \
 && rm -rf /var/lib/apt/lists/*

# Locale
RUN sed -i 's/# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# --- MiKTeX (apt repo + finished shared setup, auto-install on) ---
ARG UBUNTU_CODENAME=noble
RUN curl -fsSL https://miktex.org/download/key > /usr/share/keyrings/miktex-keyring.asc \
 && echo "deb [signed-by=/usr/share/keyrings/miktex-keyring.asc] https://miktex.org/download/ubuntu ${UBUNTU_CODENAME} universe" \
    > /etc/apt/sources.list.d/miktex.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends miktex \
 && rm -rf /var/lib/apt/lists/*

# Complete MiKTeX admin setup, enable on-the-fly install, and preinstall the usual suspects.
# (On-the-fly keeps the image light but still "fully featured" as packages are pulled when needed.)
RUN miktexsetup --shared=yes finish \
 && initexmf --admin --set-config-value [MPM]AutoInstall=1 \
 && mpm --admin --update-db \
 && mpm --admin --update \
 && mpm --admin --install=latexmk,pgf,biber,biblatex,latexindent \
 && mktexlsr

# --- Pandoc (recent stable) ---
# Pin to a known-good tag; easy to bump by editing the build arg in devcontainer.json.
ARG PANDOC_VERSION=3.7.0.2
RUN curl -fsSL -o /tmp/pandoc.deb \
      https://github.com/jgm/pandoc/releases/download/${PANDOC_VERSION}/pandoc-${PANDOC_VERSION}-1-amd64.deb \
 && apt-get update && apt-get install -y --no-install-recommends /tmp/pandoc.deb \
 && rm -f /tmp/pandoc.deb \
 && rm -rf /var/lib/apt/lists/*
# (Pandoc 3.7.x is the current line as of Aug 2025.) :contentReference[oaicite:7]{index=7}

# --- LaTeXML for additional LaTeX→HTML/MathML workflows ---
RUN apt-get update && apt-get install -y --no-install-recommends latexml \
 && rm -rf /var/lib/apt/lists/*
# LaTeXML: CLI `latexml`/`latexmlpost` for HTML5+MathML, `latexmlmath` for TeX math conversions. :contentReference[oaicite:8]{index=8}

# --- (Optional) helpers for MathML⇄LaTeX scripting with Python ---
RUN pip3 install --no-cache-dir mathml-to-latex latex2mathml
# mathml-to-latex (M↦TeX), latex2mathml (TeX↦M). Tiny footprint, handy in LLM toolflows. :contentReference[oaicite:9]{index=9}

# Create a writable workspace and switch back to the default user from the base image.
RUN mkdir -p /workspaces && chown -R coder:coder /workspaces
WORKDIR /workspaces
EXPOSE 8045 8080
USER coder

# Preinstall VS Code extensions for code-server runs (Dev Containers will install via customizations)
RUN code-server --install-extension James-Yu.latex-workshop \
 && code-server --install-extension efoerster.texlab \
 && code-server --install-extension yzhang.markdown-all-in-one \
 && code-server --install-extension streetsidesoftware.code-spell-checker
