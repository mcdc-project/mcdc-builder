#!/bin/bash -x

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# Resolve subsequent work from the home directory.
cd

# =============================================================================
# Configuration
# =============================================================================

# Choose the MC/DC branch, environment name, and Python version.
MCDC_BRANCH="main"
VENV_NAME="mcdc"
PYTHON_VERSION="3.13.2"

# Locate the source checkout and environment under the workspace.
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/dane/$VENV_NAME"
MCDC_DIR="$WORKSPACE/MCDC"

# =============================================================================
# Machine modules
# =============================================================================

# Restore the site defaults and load Python and MPI.
module restore system
module load "python/$PYTHON_VERSION"
module load mvapich2/2.3.7
module load mvapich2-tce/2.3.7

# =============================================================================
# Python environment
# =============================================================================

# Replace the existing environment with a clean one.
rm -rf "$VENV_PATH"
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Activate the environment before installing packages.
source "$VENV_PATH/bin/activate"

# Refresh the package installation tools.
pip install --upgrade pip
pip install --upgrade setuptools

# =============================================================================
# MC/DC installation
# =============================================================================

# Install the selected branch with development dependencies in editable mode.
cd "$MCDC_DIR"
git checkout "$MCDC_BRANCH"
pip install -e ".[dev]"
