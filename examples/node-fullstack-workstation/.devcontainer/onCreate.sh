#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up Node.js Full-Stack workstation..."

# Print Node.js environment information
echo "📋 Node.js environment:"
node --version
npm --version
pnpm --version
echo "npm global prefix: $(npm config get prefix)"
echo "Node.js location: $(which node)"

echo ""
echo "🛠️  Verifying package managers..."

# Verify corepack is working
echo "Corepack enabled: $(corepack --version)"

# Check if package.json exists and install dependencies
if [ -f "package.json" ]; then
    echo ""
    echo "📦 Found package.json - installing dependencies with pnpm..."
    pnpm install
    
    # Check if playwright is in dependencies and install browser deps
    if pnpm list playwright &>/dev/null || pnpm list @playwright/test &>/dev/null; then
        echo ""
        echo "🎭 Playwright detected - installing browser dependencies..."
        # Install Playwright browser binaries
        pnpm exec playwright install-deps || echo "⚠️  Playwright install-deps failed (this is normal if not using Playwright)"
        pnpm exec playwright install || echo "⚠️  Playwright install failed (this is normal if not using Playwright)"
    fi
else
    echo ""
    echo "📋 No package.json found. You can create a new project with:"
    echo "   pnpm create vite@latest my-app"
    echo "   pnpm create next-app@latest my-app"
    echo "   pnpm create react-app my-app"
fi

echo ""
echo "✅ Development tools available:"
echo "   pnpm: $(pnpm --version)"
echo "   Node.js: $(node --version)"

echo ""
echo "🎉 Node.js Full-Stack workstation setup complete!"
echo ""
echo "💡 Available commands:"
echo "   pnpm create vite@latest       - Create a new Vite project"
echo "   pnpm create next-app@latest   - Create a new Next.js project"  
echo "   pnpm install                  - Install dependencies"
echo "   pnpm dev                      - Start development server"
echo "   pnpm build                    - Build for production"
echo "   pnpm test                     - Run tests"
echo "   pnpm lint                     - Run ESLint"
echo "   pnpm format                   - Format code with Prettier"
echo ""
echo "📱 Forwarded ports:"
echo "   :3000 - API/Backend server"
echo "   :5173 - Vite development server"