Goal: Rust workstation with stable toolchain, clippy, rustfmt, cargo-nextest, cross.

Requirements:
- Base on `ghcr.io/devcontainers/images/base` + rustup.
- Install components: clippy, rustfmt; tools: cargo-nextest, cargo-edit, cross.
- OS deps: build-essential, pkg-config, libssl-dev.
- VS Code extensions: rust-lang.rust-analyzer.
- onCreate.sh: rustup update stable; add components; print `rustc -Vv`.

