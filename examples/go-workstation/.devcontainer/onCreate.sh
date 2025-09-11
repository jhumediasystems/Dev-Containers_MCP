#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up Go workstation..."

# Print Go environment information
echo "📋 Go environment:"
go version
go env GOROOT
go env GOPATH
go env GOOS
go env GOARCH

echo ""
echo "🛠️  Installing Go tools..."

# Install staticcheck (static analysis)
echo "Installing staticcheck..."
go install honnef.co/go/tools/cmd/staticcheck@latest

# Install golangci-lint (comprehensive linter)
echo "Installing golangci-lint..."
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.55.2

# Install goreleaser (release automation)
echo "Installing goreleaser..."
go install github.com/goreleaser/goreleaser@latest

# Verify installations
echo ""
echo "✅ Installed tools:"
echo "   staticcheck: $(staticcheck --version 2>/dev/null || echo 'not found')"
echo "   golangci-lint: $(golangci-lint --version 2>/dev/null || echo 'not found')"
echo "   goreleaser: $(goreleaser --version 2>/dev/null || echo 'not found')"

echo ""
echo "🎉 Go workstation setup complete!"
echo ""
echo "💡 Available commands:"
echo "   go mod init <module-name>  - Initialize a new Go module"
echo "   staticcheck ./...          - Run static analysis"
echo "   golangci-lint run          - Run comprehensive linting"
echo "   goreleaser init            - Initialize release configuration"
echo "   go test ./...              - Run all tests"
echo "   go build                   - Build the project"