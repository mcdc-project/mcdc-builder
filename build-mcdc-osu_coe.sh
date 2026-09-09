#!/bin/bash

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Pick optional groups (dev, docs, vvp), or use "." for core dependencies only.
MCDC_DEPENDENCIES=".[dev,docs,vvp]"

# Select the Python environment.
VENV_NAME="mcdc"
PYTHON_VERSION="3.13"

# Select the site package manager, compiler, and MPI modules.
CONDA_MODULE="conda/25.3"
COMPILER_MODULE="intel/oneapi"
MPI_MODULE="mpi/latest"

# Locate the existing MC/DC checkout; Conda manages the environment path.
WORKSPACE="$HOME"
MCDC_DIR="$WORKSPACE/mcdc"

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

# Install the manually prepared MC/DC checkout with the selected dependencies.
cd "$MCDC_DIR"
python -m pip install -e "$MCDC_DEPENDENCIES"
