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
PYTHON_VERSION="3.13"

# Locate the existing MC/DC checkout; Conda manages the environment path.
WORKSPACE="$HOME"
MCDC_DIR="$WORKSPACE/MCDC"

# =============================================================================
# Machine modules
# =============================================================================

# Load the scheduler, Conda, compiler, and MPI modules.
module purge
module load slurm
module load conda/25.3
module load intel/oneapi
module load mpi/latest

# =============================================================================
# Python environment
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
