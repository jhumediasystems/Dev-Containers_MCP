# Go Workstation

A development container environment for Go development with common linters and release tooling.

## What's Included

### Base Image
- `mcr.microsoft.com/devcontainers/go:1-1.21-bookworm`
- Go 1.21 with full development environment

### Tools Pre-installed
- **staticcheck**: Static analysis tool for Go programs
- **golangci-lint**: Comprehensive Go linter aggregating multiple tools
- **goreleaser**: Release automation tool for Go projects

### VS Code Extensions
- `golang.go`: Official Go extension for VS Code with IntelliSense, debugging, and more

### OS Dependencies
- `ca-certificates`, `curl`, `git`, `build-essential`

## Getting Started

1. Open this folder in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette: "Remote-Containers: Reopen in Container"
3. Wait for the container to build and initialize
4. Start coding!

## Common Commands

### Initialize a new Go module
```bash
go mod init your-module-name
```

### Run static analysis
```bash
staticcheck ./...
```

### Run comprehensive linting
```bash
golangci-lint run
```

### Run tests
```bash
go test ./...
```

### Build the project
```bash
go build
```

### Initialize release configuration
```bash
goreleaser init
```

## Project Structure

This workstation is designed to work with any Go project structure. Simply place your Go source files in the workspace and use the tools provided.

## Environment Information

The onCreate script will display Go environment information when the container is first created, including:
- Go version
- GOROOT and GOPATH
- Target OS and architecture

## Notes

- All Go tools are installed to `$GOPATH/bin` which is included in the PATH
- The container runs as the `vscode` user for security and compatibility
- golangci-lint is installed using the official installation script for best compatibility