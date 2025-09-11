#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Setting up Python Data Science workstation..."

# Source venv activation
source ~/.bashrc

echo "📋 Python environment:"
python3 --version
which python3
echo "Virtual environment: /home/vscode/.venv/ds"

echo ""
echo "📦 Installing data science packages..."

# Activate the data science virtual environment and install packages
source /home/vscode/.venv/ds/bin/activate

# Install core data science packages
pip install --no-cache-dir \
    numpy \
    pandas \
    scipy \
    matplotlib \
    seaborn \
    scikit-learn \
    jupyterlab \
    ipywidgets \
    notebook \
    ipykernel \
    black \
    isort \
    flake8 \
    pytest

echo ""
echo "🔧 Configuring Jupyter..."

# Register the kernel with Jupyter
python -m ipykernel install --user --name=ds --display-name "Python (ds)"

# Create Jupyter config directory
mkdir -p ~/.jupyter

# Configure Jupyter for container use
cat > ~/.jupyter/jupyter_lab_config.py << 'EOF'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.token = ''
c.ServerApp.password = ''
c.ServerApp.allow_root = True
c.ServerApp.allow_origin = '*'
c.ServerApp.disable_check_xsrf = True
EOF

echo ""
echo "✅ Environment setup complete!"
echo ""
echo "🔍 Installed packages:"
pip list

echo ""
echo "🎉 Python Data Science workstation setup complete!"
echo ""
echo "💡 Available commands:"
echo "   source ~/.venv/ds/bin/activate  - Activate the data science environment"
echo "   jupyter lab                     - Start Jupyter Lab (available on port 8888)"
echo "   jupyter notebook                - Start Jupyter Notebook"  
echo "   python -m ipykernel install     - Register new kernel"
echo "   black <file.py>                 - Format Python code"
echo "   isort <file.py>                 - Sort imports"
echo "   flake8 <file.py>                - Lint Python code"
echo ""
echo "📊 Data Science Libraries Available:"
echo "   - NumPy: Numerical computing"
echo "   - Pandas: Data manipulation and analysis"
echo "   - Matplotlib/Seaborn: Data visualization"
echo "   - Scikit-learn: Machine learning"
echo "   - SciPy: Scientific computing"
echo "   - Jupyter Lab: Interactive computing environment"
echo ""
echo "🌐 Jupyter Lab will be available at: http://localhost:8888"
echo ""
echo "💡 To install conda later (optional):"
echo "   wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
echo "   bash Miniconda3-latest-Linux-x86_64.sh"