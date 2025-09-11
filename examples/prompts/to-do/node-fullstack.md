Goal: Node.js full-stack workstation with pnpm, Vite, Playwright, eslint/prettier, TS optional.

Requirements:
- Base on `ghcr.io/devcontainers/images/javascript-node` with Node 20+.
- Global tools: corepack enable; pnpm latest.
- Project dev deps: typescript, ts-node/tsx, vite, vitest, playwright, eslint, prettier.
- OS deps: git, curl.
- VS Code extensions: dbaeumer.vscode-eslint, esbenp.prettier-vscode, ms-playwright.playwright.
- onCreate.sh: pnpm install if package.json exists; playwright install-deps if using browser tests.
- Forward ports typical for Vite (5173) and API (3000), auto-forward notify.

