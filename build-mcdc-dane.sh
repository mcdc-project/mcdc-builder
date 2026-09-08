#!/bin/bash

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Select the source branch and Python environment.
MCDC_BRANCH="main"
VENV_NAME="mcdc"
PYTHON_VERSION="3.13.2"

# Load matching MPI runtime and compiler-wrapper modules.
MPI_MODULE="mvapich2/2.3.7"
MPI_COMPILER_MODULE="mvapich2-tce/2.3.7"

# Locate the source checkout and environment under the workspace.
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/dane/$VENV_NAME"
MCDC_DIR="$WORKSPACE/MCDC"

# =============================================================================
# Module environment
# =============================================================================

# Restore the site defaults and load Python and MPI.
module restore system
module load "python/$PYTHON_VERSION"
module load "$MPI_MODULE"
module load "$MPI_COMPILER_MODULE"

# =============================================================================
# Environment creation
# =============================================================================

# Replace the existing environment with a clean one.
rm -rf "$VENV_PATH"
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Activate the environment before installing packages.
source "$VENV_PATH/bin/activate"

# =============================================================================
# Package installation tools
# =============================================================================

# Upgrade the installers inside the activated environment.
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools

# =============================================================================
# MC/DC installation
# =============================================================================

# Select the local branch and install MC/DC with development dependencies.
cd "$MCDC_DIR"
git switch "$MCDC_BRANCH"
python -m pip install -e ".[dev]"
