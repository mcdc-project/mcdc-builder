#!/bin/bash

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Select the Python environment.
VENV_NAME="mcdc"
PYTHON_VERSION="3.11"

# Install MC/DC in editable mode; set false for a regular installation.
MCDC_EDITABLE="true"

# Pick optional groups (dev, docs, vvp), or use "." for core dependencies only.
MCDC_DEPENDENCIES=".[dev,docs,vvp]"

# Select the NVIDIA CUDA, compiler, and MPI modules.
CUDA_MODULE="cuda/11.8"
COMPILER_MODULE="gcc/10.3"
MPI_MODULE="mpich/4.0h_gcc-10"

# Select the Numba version compatible with the NVIDIA GPU toolchain.
NUMBA_VERSION="0.63.1"

# Locate the source checkouts and environment under the workspace.
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/osu_coe_nvidia/$VENV_NAME"
MCDC_DIR="$WORKSPACE/mcdc"
HARMONIZE_DIR="$WORKSPACE/harmonize"

# =============================================================================
# Module environment
# =============================================================================

# Load CUDA, Python, the compiler, and MPI into the current module environment.
module load "$CUDA_MODULE"
module load "python/$PYTHON_VERSION"
module load "$COMPILER_MODULE"
module load "$MPI_MODULE"

# =============================================================================
# Environment creation
# =============================================================================

# Replace the existing environment with a clean one.
rm -rf "$VENV_PATH"
python -m venv "$VENV_PATH"

# Restore the GPU toolchain and MPI whenever the environment is activated.
# Python is already selected by the venv; loading its module here changes PATH.
cat >> "$VENV_PATH/bin/activate" <<EOF

# Load the CUDA, compiler, and MPI modules used by this environment.
module load "$CUDA_MODULE" || return 1
module load "$COMPILER_MODULE" || return 1
module load "$MPI_MODULE" || return 1
EOF

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

# Install the manually prepared MC/DC checkout with the selected dependencies.
cd "$MCDC_DIR"
if [ "$MCDC_EDITABLE" = "true" ]; then
    python -m pip install --no-cache-dir -e "$MCDC_DEPENDENCIES"
else
    python -m pip install --no-cache-dir "$MCDC_DEPENDENCIES"
fi

# =============================================================================
# GPU dependencies
# =============================================================================

# Install the manually prepared Harmonize checkout in editable mode.
cd "$HARMONIZE_DIR"
python -m pip install --no-cache-dir -e .

# Pin Numba after the editable installations.
python -m pip install "numba==$NUMBA_VERSION"
