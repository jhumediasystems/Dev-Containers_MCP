Goal: Cloud-native ops/dev workstation: kubectl, kind, helm, kustomize, terraform, plus AWS/GCP/Azure CLIs.

Requirements:
- Base on `ghcr.io/devcontainers/features/common-utils` + `docker-in-docker` if needed.
- Tools: kubectl (stable), helm (stable), kustomize, kind, terraform (latest stable), yq/jq.
- Optional cloud CLIs: awscli v2, gcloud SDK, azure-cli.
- VS Code extensions: ms-kubernetes-tools.vscode-kubernetes-tools, hashicorp.terraform.
- onCreate.sh: print versions, create a local kind cluster if requested via env.
- Forward typical dashboard ports as needed.

