#!/bin/bash

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Select the source branch and Python environment.
MCDC_BRANCH="main"
VENV_NAME="mcdc"
PYTHON_VERSION="3.13"

# Select the site package manager, compiler, and MPI modules.
CONDA_MODULE="conda/25.3"
COMPILER_MODULE="intel/oneapi"
MPI_MODULE="mpi/latest"

# Locate the existing MC/DC checkout; Conda manages the environment path.
WORKSPACE="$HOME"
MCDC_DIR="$WORKSPACE/MCDC"

# =============================================================================
# Module environment
# =============================================================================

# Load the scheduler, Conda, compiler, and MPI modules.
module purge
module load slurm
module load "$CONDA_MODULE"
module load "$COMPILER_MODULE"
module load "$MPI_MODULE"

# =============================================================================
# Environment creation
# =============================================================================

# Detect an existing environment; query or parsing failures stop the build.
ENV_EXISTS=$(conda env list --json | python -c '
import json
import os
import sys

envs = json.load(sys.stdin)["envs"]
print("true" if any(os.path.basename(os.path.normpath(path)) == sys.argv[1]
                    for path in envs) else "false")
' "$VENV_NAME")

# Skip removal on a first build, but stop if removal fails.
if [ "$ENV_EXISTS" = "true" ]; then
    conda env remove --name "$VENV_NAME" --yes
fi

# Create the requested Python environment without interactive prompts.
conda create --name "$VENV_NAME" python="$PYTHON_VERSION" --yes

# Activate the environment before installing packages.
conda activate "$VENV_NAME"

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
