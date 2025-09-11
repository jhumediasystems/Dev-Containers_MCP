Goal: A reproducible Python Data Science workstation with Conda/mamba, Jupyter, common DS libs (numpy, pandas, matplotlib, scikit-learn), and VS Code data tooling.

Requirements:
- Base on `ghcr.io/devcontainers/images/python` (or `miniconda` feature) with Ubuntu LTS.
- Include `mamba` or `micromamba` for fast env solve; create env named `ds`.
- Packages: numpy, pandas, scipy, matplotlib, seaborn, scikit-learn, jupyterlab, ipywidgets.
- OS deps: git, curl, build-essential, gfortran, libopenblas-dev, libssl-dev.
- VS Code extensions: ms-python.python, ms-toolsai.jupyter, ms-toolsai.datawrangler.
- Ports: 8888 for Jupyter; set host 0.0.0.0; password/token disabled inside Codespaces.
- onCreate.sh: create env, install deps, register Jupyter kernel.

