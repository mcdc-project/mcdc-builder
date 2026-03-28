#!/bin/bash -x
cd

# =============================================================================
# Setups
# =============================================================================

# MC/DC branch
MCDC_BRANCH="main"

# Name for the virtual environment
VENV_NAME="mcdc"

# Python versions
PYTHON_VERSION="3.13.2"

# Paths
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/dane/$VENV_NAME"
MCDC_DIR="$WORKSPACE/MCDC"

# =============================================================================
# Preparation
# =============================================================================

# Set modules
module restore system
module load "python/$PYTHON_VERSION"
module load mvapich2/2.3.7
module load mvapich2-tce/2.3.7

# =============================================================================
# Create Python environment
# =============================================================================

# Remove any pre-existing instance of the environment
rm -rf "$VENV_PATH"

# Create the environment
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Activate the venv
source "$VENV_PATH/bin/activate"

# Make sure we are working with a recent version of pip and setuptools
pip install --upgrade pip
pip install --upgrade setuptools

# =============================================================================
# Install MC/DC
# =============================================================================

# MC/DC
cd "$MCDC_DIR"
git checkout "$MCDC_BRANCH"
pip install -e .[dev]
