# Node.js Full-Stack Workstation

A comprehensive development container environment for Node.js full-stack development with pnpm, Vite, Playwright, ESLint, Prettier, and TypeScript support.

## What's Included

### Base Image
- `mcr.microsoft.com/devcontainers/javascript-node:1-20-bookworm`
- Node.js 20+ with full development environment

### Package Managers & Tools
- **pnpm**: Fast, disk space efficient package manager
- **corepack**: For package manager management
- **npm**: Default Node.js package manager
- **Playwright**: End-to-end testing framework (browser dependencies included)

### Development Dependencies Support
- **TypeScript** with ts-node/tsx for TypeScript execution
- **Vite** for fast build tooling and development server
- **Vitest** for fast unit testing
- **ESLint** for code linting
- **Prettier** for code formatting
- **Playwright** for browser automation and testing

### VS Code Extensions
- `dbaeumer.vscode-eslint`: ESLint integration
- `esbenp.prettier-vscode`: Prettier code formatter
- `ms-playwright.playwright`: Playwright test runner integration
- `bradlc.vscode-tailwindcss`: Tailwind CSS IntelliSense
- `ms-vscode.vscode-typescript-next`: Enhanced TypeScript support

### OS Dependencies
- `ca-certificates`, `curl`, `git`, `build-essential`
- Playwright browser dependencies for headless browser testing

### Port Forwarding
- **Port 3000**: API/Backend server (auto-forward with notification)
- **Port 5173**: Vite development server (auto-forward with notification)

## Getting Started

1. Open this folder in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette: "Remote-Containers: Reopen in Container"
3. Wait for the container to build and initialize
4. Start developing!

## Creating New Projects

### Create a Vite Project
```bash
pnpm create vite@latest my-app
cd my-app
pnpm install
pnpm dev
```

### Create a Next.js Project
```bash
pnpm create next-app@latest my-app
cd my-app
pnpm dev
```

### Create a React App
```bash
pnpm create react-app my-app
cd my-app
pnpm start
```

## Common Commands

### Package Management
```bash
pnpm install              # Install dependencies
pnpm add <package>        # Add a dependency
pnpm add -D <package>     # Add a dev dependency
pnpm remove <package>     # Remove a dependency
```

### Development
```bash
pnpm dev                  # Start development server
pnpm build                # Build for production
pnpm start                # Start production server
pnpm preview              # Preview production build
```

### Testing
```bash
pnpm test                 # Run tests
pnpm test:ui              # Run tests with UI (if using Vitest)
pnpm test:e2e             # Run end-to-end tests (if using Playwright)
```

### Code Quality
```bash
pnpm lint                 # Run ESLint
pnpm lint:fix             # Fix ESLint issues
pnpm format               # Format code with Prettier
pnpm type-check           # TypeScript type checking
```

### Playwright Browser Testing
```bash
npx playwright install    # Install browsers (done automatically)
npx playwright test       # Run Playwright tests
npx playwright test --ui  # Run tests with UI mode
```

## Project Structure

This workstation supports various project structures:
- **Vite + React/Vue/Svelte**: Modern SPA development
- **Next.js**: Full-stack React applications
- **Express/Fastify APIs**: Backend API development
- **Monorepos**: Multi-package repositories
- **TypeScript projects**: Full TypeScript support

## Environment Features

- **Format on Save**: Automatic code formatting with Prettier
- **Auto Port Forwarding**: Development servers are automatically accessible
- **TypeScript Support**: Enhanced TypeScript language features
- **ESLint Integration**: Real-time code linting
- **Playwright Integration**: Visual test runner in VS Code

## Package.json Detection

The onCreate script automatically:
- Detects if a `package.json` exists and runs `pnpm install`
- Installs Playwright browser dependencies if Playwright is detected
- Provides helpful commands and information for getting started

## Notes

- pnpm is used for faster installs and better disk space efficiency
- Playwright browser dependencies are pre-installed for immediate testing
- TypeScript configuration is automatically detected and supported
- All tools work together seamlessly for modern full-stack development