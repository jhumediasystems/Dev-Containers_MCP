Goal: Go workstation with common linters and release tooling.

Requirements:
- Base on `ghcr.io/devcontainers/images/go`.
- Tools: staticcheck, golangci-lint (optional), goreleaser.
- VS Code extensions: golang.go.
- onCreate.sh: `go install` required tools; `go env` printout.

