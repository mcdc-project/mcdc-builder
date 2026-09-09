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
ROCM_DIR="/opt/rocm-$ROCM_VERSION"

# Select Numba for the HIP backend.
NUMBA_VERSION="0.61.0"

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

# Restore the GPU toolchain on activation, including after node login resets.
if [ "$WITH_GPU" = "true" ]; then
    cat >> "$VENV_PATH/bin/activate" <<EOF

# Load the ROCm version used to build this environment.
if ! module load "rocm/$ROCM_VERSION"; then
    printf '%s\n' "Failed to load rocm/$ROCM_VERSION for this environment." >&2
    return 1
fi

# Require the compiler tools before exposing the ROCm paths.
if [ ! -x "$ROCM_DIR/bin/hipcc" ] || [ ! -x "$ROCM_DIR/llvm/bin/llvm-as" ]; then
    printf '%s\n' "Missing hipcc or llvm-as under $ROCM_DIR." >&2
    return 1
fi

# HIP Numba uses ROCm variables; Harmonize discovers hipcc through PATH.
export ROCM_PATH="$ROCM_DIR"
export ROCM_HOME="$ROCM_DIR"
export PATH="$ROCM_DIR/bin:$ROCM_DIR/llvm/bin:\$PATH"
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

# Install the manually prepared MC/DC checkout with the selected dependencies.
cd "$MCDC_DIR"
python -m pip install -e "$MCDC_DEPENDENCIES"

# =============================================================================
# MPI bindings
# =============================================================================

# Compile mpi4py with the loaded Cray MPI compiler wrapper.
CC=cc MPICC=cc python -m pip install --no-binary=mpi4py "mpi4py==$MPI4PY_VERSION"
