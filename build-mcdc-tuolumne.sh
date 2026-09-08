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
PYTHON_VERSION="3.11.5"

# Locate the source checkout and environment under the workspace.
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/tuolumne/$VENV_NAME"
MCDC_DIR="$WORKSPACE/MCDC"

# Enable the optional ROCm stack and select its source and runtime versions.
WITH_GPU="false"
HARMONIZE_BRANCH="main"
ROCM_VERSION="6.0.0"

# The LLVM checkout is replaced; the Harmonize checkout must already exist.
ROCM_LLVM_PY_DIR="$WORKSPACE/rocm_llvm_py-new"
HARMONIZE_DIR="$WORKSPACE/harmonize"

# =============================================================================
# Machine modules
# =============================================================================

# Restore the site defaults and load the Python runtime.
module restore system
module load "python/$PYTHON_VERSION"

# Load the GPU runtime only when GPU support is enabled.
if [ "$WITH_GPU" = "true" ]; then
    module load "rocm/$ROCM_VERSION"
fi

# =============================================================================
# Python environment
# =============================================================================

# Replace the existing environment with a clean one.
rm -rf "$VENV_PATH"
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Persist ROCm discovery paths for future environment activations.
if [ "$WITH_GPU" = "true" ]; then
    PATH_EXPORTS="""
    export ROCM_PATH="/opt/rocm-$ROCM_VERSION"
    export ROCM_HOME="/opt/rocm-$ROCM_VERSION"
    """
    echo "$PATH_EXPORTS" >> "$VENV_PATH/bin/activate"
fi

# Activate the environment before installing packages.
source "$VENV_PATH/bin/activate"

# Refresh the package installation tools.
pip install --upgrade pip
pip install --upgrade setuptools

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

    # Initialize the sources and disable the cpython.string Cython import.
    ./init.sh
    sed -i "s/cimport *cpython.string/#cimport cpython.string/g" "$ROCM_LLVM_PY_DIR/rocm-llvm-python/rocm/llvm/_util/types.pyx"

    # Build the wheel and clean intermediate build files.
    ./build_pkg.sh --post-clean -j 16

    # Install the last matching wheel in filename order.
    LATEST=$( ls -1 rocm-llvm-python/dist/rocm_llvm_python-${ROCM_VERSION}*.whl | tail -n 1 )
    pip install --force-reinstall "$LATEST"
    unset LATEST

    # =========================================================================
    # HIP Python bindings
    # =========================================================================

    # Match the HIP bindings and CUDA compatibility layer to the ROCm version.
    pip install -i https://test.pypi.org/simple "hip-python~=$ROCM_VERSION"
    pip install -i https://test.pypi.org/simple "hip-python-as-cuda~=$ROCM_VERSION"

    # =========================================================================
    # HIP Numba support
    # =========================================================================

    # Install the selected numerical-library versions before HIP Numba.
    pip install numba==0.60.0
    pip install cvxpy==1.7.0
    pip install scipy==1.12

    # Keep TestPyPI configuration local to this virtual environment.
    pip config --site set global.extra-index-url https://test.pypi.org/simple

    # Install the pinned HIP Numba revision without resolving dependencies.
    pip install --no-deps "git+https://github.com/ROCm/numba-hip.git@8098162162fb0babd77b56583b289d6dd6226151"

    # =========================================================================
    # Harmonize
    # =========================================================================

    # Install the selected branch from the existing checkout in editable mode.
    cd "$HARMONIZE_DIR"
    git checkout "$HARMONIZE_BRANCH"
    pip install -e .
fi

# =============================================================================
# MC/DC installation
# =============================================================================

# Install the selected branch with development dependencies in editable mode.
cd "$MCDC_DIR"
git checkout "$MCDC_BRANCH"
pip install -e ".[dev]"
