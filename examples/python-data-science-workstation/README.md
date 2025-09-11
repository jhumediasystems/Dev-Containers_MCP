# Python Data Science Workstation

A comprehensive development container environment for Python data science with virtual environments, Jupyter Lab, and essential data science libraries.

## What's Included

### Base Image
- `mcr.microsoft.com/devcontainers/python:1-3.11-bookworm`
- Python 3.11 with full development environment

### Data Science Libraries
- **NumPy**: Numerical computing and array operations
- **Pandas**: Data manipulation and analysis
- **SciPy**: Scientific computing and statistics
- **Matplotlib**: Basic plotting and visualization
- **Seaborn**: Statistical data visualization
- **Scikit-learn**: Machine learning algorithms and tools
- **Jupyter Lab**: Interactive computing environment
- **IPython & IPywidgets**: Enhanced interactive computing

### Development Tools
- **Black**: Python code formatter
- **isort**: Import statement organizer
- **Flake8**: Code linting and style checking
- **pytest**: Testing framework

### VS Code Extensions
- `ms-python.python`: Python language support with IntelliSense
- `ms-toolsai.jupyter`: Jupyter notebook support in VS Code
- `ms-toolsai.datawrangler`: Data manipulation and visualization tools
- `ms-python.isort`: Import organization
- `ms-python.black-formatter`: Code formatting
- `ms-python.flake8`: Linting support

### OS Dependencies
- Scientific computing libraries: `gfortran`, `libopenblas-dev`, `liblapack-dev`
- Build tools: `build-essential`, `git`, `curl`
- Additional utilities: `wget`, `unzip`, `bzip2`, `graphviz`

### Port Forwarding
- **Port 8888**: Jupyter Lab server (auto-forward with notification)

## Getting Started

1. Open this folder in VS Code
2. When prompted, click "Reopen in Container" or use Command Palette: "Remote-Containers: Reopen in Container"
3. Wait for the container to build and initialize (packages will be installed on first run)
4. Start coding and analyzing data!

## Environment Setup

The workstation creates a Python virtual environment at `/home/vscode/.venv/ds` with all data science packages pre-installed. The environment is automatically activated when you open a terminal.

### Starting Jupyter Lab

```bash
# Jupyter Lab will be available at http://localhost:8888
jupyter lab
```

Or use the VS Code Jupyter extension to create and run notebooks directly in the editor.

## Common Workflows

### Data Analysis Notebook
1. Create a new Jupyter notebook in VS Code or Jupyter Lab
2. Use the "Python (ds)" kernel for data science work
3. Import libraries and start analyzing:

```python
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split

# Load and explore data
df = pd.read_csv('your_data.csv')
df.head()
```

### Machine Learning Project
```python
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report

# Train a model
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Evaluate
predictions = model.predict(X_test)
print(f"Accuracy: {accuracy_score(y_test, predictions)}")
```

### Data Visualization
```python
# Create beautiful plots with seaborn
sns.set_style("whitegrid")
plt.figure(figsize=(10, 6))
sns.scatterplot(data=df, x='feature1', y='feature2', hue='category')
plt.title('Feature Relationship')
plt.show()
```

## Package Management

### Installing Additional Packages
```bash
# Activate the data science environment
source ~/.venv/ds/bin/activate

# Install new packages
pip install scikit-image plotly bokeh
```

### Popular Additional Packages
- **plotly**: Interactive visualizations
- **bokeh**: Interactive web-based visualizations  
- **scikit-image**: Image processing
- **networkx**: Network analysis
- **statsmodels**: Statistical modeling
- **xgboost**: Gradient boosting framework
- **tensorflow/pytorch**: Deep learning frameworks

## Code Quality Tools

### Formatting Code
```bash
# Format Python files
black your_script.py

# Sort imports
isort your_script.py
```

### Linting
```bash
# Check code style and quality
flake8 your_script.py
```

### Testing
```bash
# Run tests
pytest tests/
```

## Jupyter Configuration

Jupyter is pre-configured for container use:
- No authentication required (container environment)
- Available on `0.0.0.0:8888` for port forwarding
- Python (ds) kernel automatically registered

## Optional: Conda Installation

If you prefer conda over pip, you can install it later:

```bash
# Download and install miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create a conda environment
conda create -n myenv python=3.11
conda activate myenv
```

## Project Structure

This workstation supports various data science project structures:
- **Jupyter Notebooks**: Interactive analysis and exploration
- **Python Scripts**: Production data processing pipelines
- **Mixed Projects**: Combination of notebooks for exploration and scripts for production

## Environment Information

The onCreate script displays:
- Python version and location
- Virtual environment path
- Installed packages list
- Available commands and tools
- Jupyter Lab access information

## Notes

- All packages are installed in a virtual environment to avoid conflicts
- The environment is automatically activated in new terminal sessions
- VS Code is configured to use the virtual environment Python interpreter
- Jupyter kernels are properly registered for notebook support
- Package installation happens at container creation time for reliability