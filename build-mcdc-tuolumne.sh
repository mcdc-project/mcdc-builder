#!/bin/bash

# Stop on failed commands or pipelines before continuing setup.
set -eo pipefail

# =============================================================================
# Configuration
# =============================================================================

# Select the Python environment.
VENV_NAME="mcdc"
PYTHON_VERSION="3.11.5"

# Select the Cray MPI module and Python bindings.
MPI_MODULE="cray-mpich/9.0.1"
MPI4PY_VERSION="4.0.0"

# Locate the source checkout and environment under the workspace.
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/tuolumne/$VENV_NAME"
MCDC_DIR="$WORKSPACE/mcdc"

# Enable the optional GPU stack and select its ROCm version.
WITH_GPU="false"
ROCM_VERSION="7.1.1"

# Select MC/DC GPU-compatible third-party library versions.
NUMBA_VERSION="0.61.0"
SCIPY_VERSION="1.12"
NUMPY_VERSION="2.0.0"

# Leave empty to follow the HIP Numba default branch, or set a commit/tag.
HIP_NUMBA_REVISION=""

# The LLVM checkout is replaced; the Harmonize checkout must already exist.
ROCM_LLVM_PY_DIR="$WORKSPACE/rocm_llvm_py-new"
HARMONIZE_DIR="$WORKSPACE/harmonize"

# =============================================================================
# Module environment
# =============================================================================

# Load Python into the current site module environment.
module load "python/$PYTHON_VERSION"

# Load the GPU runtime only when GPU support is enabled.
if [ "$WITH_GPU" = "true" ]; then
    module load "rocm/$ROCM_VERSION"
fi

# Load MPI after Python and the optional GPU runtime.
module load "$MPI_MODULE"

# =============================================================================
# Environment creation
# =============================================================================

# Replace the existing environment with a clean one.
rm -rf "$VENV_PATH"
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Persist ROCm discovery paths for future environment activations.
if [ "$WITH_GPU" = "true" ]; then
    cat >> "$VENV_PATH/bin/activate" <<EOF

# Locate ROCm for HIP Numba.
export ROCM_PATH="/opt/rocm-$ROCM_VERSION"
export ROCM_HOME="/opt/rocm-$ROCM_VERSION"
EOF
fi

# Activate the environment before installing packages.
source "$VENV_PATH/bin/activate"

# =============================================================================
# Package installation tools
# =============================================================================

# Upgrade the installers inside the activated environment.
python -m pip install --upgrade pip
python -m pip install --upgrade setuptools

# =============================================================================
# Optional GPU dependencies
# =============================================================================

# Build and install GPU support before installing MC/DC.
if [ "$WITH_GPU" = "true" ]; then
    # =========================================================================
    # ROCm LLVM bindings
    # =========================================================================

    # Replace the source checkout and select the requested ROCm release.
    rm -rf "$ROCM_LLVM_PY_DIR"
    git clone https://github.com/ROCm/rocm-llvm-python "$ROCM_LLVM_PY_DIR"
    cd "$ROCM_LLVM_PY_DIR"
    git checkout "release/rocm-rel-$ROCM_VERSION"

    # Build the LLVM wheel and clean intermediate build files.
    ./build.sh --post-clean

    # Install the last matching wheel in filename order.
    LATEST=$( ls -1 rocm-llvm-python/dist/rocm_llvm_python-${ROCM_VERSION}*.whl | tail -n 1 )
    python -m pip install --force-reinstall "$LATEST"
    unset LATEST

    # =========================================================================
    # HIP Python bindings
    # =========================================================================

    # Match the HIP bindings and CUDA compatibility layer to the ROCm version.
    python -m pip install -i https://test.pypi.org/simple "hip-python~=$ROCM_VERSION"
    python -m pip install -i https://test.pypi.org/simple "hip-python-as-cuda~=$ROCM_VERSION"

    # =========================================================================
    # HIP Numba support
    # =========================================================================

    # Pin Numba before installing its HIP backend.
    python -m pip install "numba==$NUMBA_VERSION"

    # Keep TestPyPI configuration local to this virtual environment.
    python -m pip config --site set global.extra-index-url https://test.pypi.org/simple

    # Install HIP Numba without resolving dependencies; append a ref if specified.
    python -m pip install --no-deps "git+https://github.com/ROCm/numba-hip.git${HIP_NUMBA_REVISION:+@$HIP_NUMBA_REVISION}"

    # =========================================================================
    # Harmonize
    # =========================================================================

    # Install the manually prepared Harmonize checkout in editable mode.
    cd "$HARMONIZE_DIR"
    python -m pip install -e .
fi

# =============================================================================
# MC/DC installation
# =============================================================================

# Install the manually prepared MC/DC checkout with development dependencies.
cd "$MCDC_DIR"
python -m pip install -e ".[dev]"

# =============================================================================
# MPI bindings
# =============================================================================

# Compile mpi4py with the loaded Cray MPI compiler wrapper.
CC=cc MPICC=cc python -m pip install --no-binary=mpi4py "mpi4py==$MPI4PY_VERSION"

# =============================================================================
# GPU numerical-library versions
# =============================================================================

# Apply explicit numerical-library pins after installing MC/DC and MPI bindings.
if [ "$WITH_GPU" = "true" ]; then
    python -m pip install "scipy==$SCIPY_VERSION"
    python -m pip install "numpy==$NUMPY_VERSION"
fi
