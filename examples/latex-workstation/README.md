# LaTeX Workstation for Web VSCode or Github Codespaces

## What you get

- A compact, reproducible **LaTeX workstation** that’s at home in **GitHub Codespaces**, **VS Code Dev Containers**, or **code‑server**.

- **MiKTeX** (auto‑installs packages like TikZ on the fly), **Pandoc** (current), **LaTeXML**, **LaTeX Workshop**/**TexLab**, fixed **PDF preview port**, and tiny **MathML helpers**—all in one container built from a **GHCR** base.

## How to use

### A) GitHub Codespaces (recommended)

1. Push this repo and click **“Create codespace”**.

2. Wait for the container to build (first run only).

3. Open `examples/tikz-main.tex`, press **⌘/Ctrl+S** to trigger LaTeX Workshop’s build, then use **“View in browser”** (or the “PORTS” tab → open port **8045**).
   
   > LaTeX Workshop serves PDF via a small HTTP server; we fix the port and host for predictable forwarding. Note this server is visible to other users on the same host unless you restrict access. [GitHub](https://github.com/James-Yu/LaTeX-Workshop/wiki/Remote?utm_source=chatgpt.com)

### B) VS Code Dev Containers (local Docker)

1. Install the **Dev Containers** extension.

2. `File → Open Folder` (this repo) → **Reopen in Container**.

3. Same as above for preview: **port 8045**. (The PDF viewer is also available in an editor tab.)

### C) code‑server in a browser (local)

`docker compose up --build # Visit http://localhost:8080 # PDF preview lives at http://localhost:8045 when you "View in browser" from LaTeX Workshop`

---

## MCP Setup

This environment is best with a coding agent in the IDE. This repo is set up to build the development environment, place you in it, start an MCP server from within the environment to provide your coding agent (github copilot in this example) the full context of the container so it will be pretty good at doing things with tex files, and provide the most common commands in an env file that it will use to carry out tasks and get around the tools.

VSCode workflow

1. Open in a Codespace or devcontainer and let the docker container build

2. ```bash
   ./scripts/add-mcp-to-devcontainer.sh
   ```

3. Ctrl+Shift+P, 'List MCP Servers,' 'codeuse', start codeuse MCP server

4. Select 'agent' mode, in the tools dropdown, ensure the 'codeuse' MCP server tools are enabled.

5. Prompt in natural language what you want to accomplish or ask clarifying questions!

---

# Manual operation

## MathML workflows

**LaTeX → HTML5 + MathML (Pandoc):**

`pandoc -f latex -t html5 --standalone --mathml input.tex -o output.html`

Pandoc’s manual documents `--mathml` and its math handling; Pandoc 3.7.x is current as of Aug 2025. [pandoc.org](https://pandoc.org/demo/example33/8.13-math.html?utm_source=chatgpt.com)[GitHub](https://github.com/jgm/pandoc/releases)

**MathML → LaTeX (two practical options):**

1. **Wrap MathML in HTML and use Pandoc’s HTML reader → LaTeX writer.** Pandoc uses the `texmath` library that supports reading/writing Presentation MathML; embedding MathML in HTML is a reliable way to round‑trip math back to LaTeX. [Hackage](https://hackage.haskell.org/package/texmath?utm_source=chatgpt.com)[pandoc.org](https://pandoc.org/?utm_source=chatgpt.com)

`cat > mml.html <<'HTML' <!doctype html><meta charset="utf-8"><body> <math xmlns="http://www.w3.org/1998/Math/MathML"> ... </math> </body> HTML pandoc -f html -t latex mml.html -o recovered.tex`

2. **Use the tiny Python helper installed in the image:**

`python  -c "import sys; from mathml_to_latex import convert; print(convert(sys.stdin.read()))" < equation.mathml > recovered.tex`

This leverages the `mathml-to-latex` library; for the other direction there’s `latex2mathml`. Both are preinstalled in this container. [PyPI+1](https://pypi.org/project/mathml-to-latex/?utm_source=chatgpt.com)

**Alternative HTML/MathML pipeline (LaTeXML):**

`# LaTeX -> XML -> HTML5 (+MathML by default) latexml --dest=doc.xml input.tex latexmlpost --dest=doc.html doc.xml # For math-only conversions: latexmlmath --pmml='eq.xml' 'E=mc^2'`

LaTeXML is included so you can compare outputs against Pandoc in workflows that need high‑fidelity HTML/MathML. [math.nist.gov+1](https://math.nist.gov/~BMiller/LaTeXML/ussage.html?utm_source=chatgpt.com)

---

## Why this approach

- **Base image from GHCR:** We pick `ghcr.io/coder/code-server:*` as a broadly used, stable base that runs well in CI and developer laptops while doubling as a web IDE when not in Codespaces. [GitHub](https://github.com/coder/code-server/pkgs/container/code-server/?utm_source=chatgpt.com)

- **MiKTeX for “feels like Windows/TeXstudio/Overleaf” users:** MiKTeX’s **on‑the‑fly install** keeps the image small while still “fully featured” (packages appear as needed—TikZ/PGF, etc.). We apply MiKTeX’s recommended Linux install and finish steps, with modern `signed-by` keyring usage for the apt repo. [MiKTeX](https://miktex.org/howto/install-miktex-unx?utm_source=chatgpt.com)[GitHub](https://github.com/MiKTeX/miktex-packaging/issues/483)

- **Pandoc pinned to recent stable:** We install a **current 3.7.x** directly from the official releases to get the latest math and table behaviors; distro packages often lag. You can bump the version via the `PANDOC_VERSION` build arg. [GitHub](https://github.com/jgm/pandoc/releases)

- **VS Code as the editor + predictable PDF preview port:** LaTeX Workshop’s PDF viewer runs an HTTP server in remote contexts; we fix it to **8045** and set host to `0.0.0.0` so Codespaces/Containers can forward it cleanly. Security note is in the LaTeX Workshop docs. [GitHub](https://github.com/James-Yu/LaTeX-Workshop/wiki/Remote?utm_source=chatgpt.com)

- **Overleaf‑style UI?** Overleaf CE is heavy and multi‑container. If you truly need it, GHCR community images exist (e.g., `ghcr.io/lcpu-club/sharelatex`), but they’re 5–7 GB and introduce operational complexity; that’s why it’s **not** bundled here. The VS Code + LaTeX Workshop workflow covers the “Overleaf feel” for most academic users. [GitHub](https://github.com/lcpu-club/overleaf/pkgs/container/sharelatex?utm_source=chatgpt.com)

---

## Quick commands you’ll actually use

- **Compile (LaTeX Workshop)**: Save the file or run *LaTeX Workshop: Build LaTeX project*.

- **CLI compile**: `latexmk -pdf -outdir=build examples/tikz-main.tex` (MiKTeX installs missing packages automatically on first run). [MiKTeX](https://miktex.org/howto/install-miktex-unx?utm_source=chatgpt.com)

- **Pandoc (docx, html, mathml, etc.)**:
  
  - `pandoc paper.tex -o paper.html -t html5 --mathml` (LaTeX→HTML+MathML) [pandoc.org](https://pandoc.org/demo/example33/8.13-math.html?utm_source=chatgpt.com)
  
  - `pandoc paper.tex -o paper.docx`

- **MathML → LaTeX**: see the two options above (Pandoc via HTML wrapper or `mathml-to-latex`).

---

## Notes & caveats

- **LaTeX Workshop PDF server**: when working on shared hosts, remember the preview server is a simple HTTP server. In Codespaces, the forwarded URL is private to your session; on shared Docker hosts, consider firewalling. [GitHub](https://github.com/James-Yu/LaTeX-Workshop/wiki/Remote?utm_source=chatgpt.com)

- **MiKTeX on Ubuntu**: this Dockerfile targets Ubuntu **24.04 “noble”**; if you need **22.04 “jammy”**, change `UBUNTU_CODENAME` in `devcontainer.json`. The MiKTeX repo supports current LTS releases; if you hit dependency issues, the MiKTeX packaging issue tracker shows the modern install line with `signed-by`. [GitHub](https://github.com/MiKTeX/miktex-packaging/issues/483)

- **MathML parsing**: Pandoc writes MathML (`--mathml`). Reading raw MathML is most reliable when embedded in HTML; otherwise use the tiny Python helper. (Pandoc’s math conversion is powered by `texmath`.) [pandoc.org](https://pandoc.org/demo/example33/8.13-math.html?utm_source=chatgpt.com)[Hackage](https://hackage.haskell.org/package/texmath?utm_source=chatgpt.com)

---
