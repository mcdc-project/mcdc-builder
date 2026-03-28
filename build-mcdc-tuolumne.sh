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
PYTHON_VERSION="3.11.5"

# Paths
WORKSPACE="$HOME"
VENV_PATH="$WORKSPACE/venv/tuolumne/$VENV_NAME"
MCDC_DIR="$WORKSPACE/MCDC"

# =================
# Setups - GPU mode
# =================

WITH_GPU="false"

# Harmonize branch
HARMONIZE_BRANCH="main"

# ROCm versions
ROCM_VERSION="6.0.0"

# Paths
ROCM_LLVM_PY_DIR="$WORKSPACE/rocm_llvm_py-new"
HARMONIZE_DIR="$WORKSPACE/harmonize"

# =============================================================================
# Preparation
# =============================================================================

# Set modules
module restore system
module load "python/$PYTHON_VERSION"
if [ "$WITH_GPU" = "true" ]; then
    # Load necessary modules
    module load "rocm/$ROCM_VERSION"
fi

# =============================================================================
# Create Python environment
# =============================================================================

# Remove any pre-existing instance of the environment
rm -rf "$VENV_PATH"

# Create the environment
"/usr/tce/packages/python/python-$PYTHON_VERSION/bin/virtualenv" "$VENV_PATH"

# Add ROCm paths to the environment (to help hip-numba later)
if [ "$WITH_GPU" = "true" ]; then
    PATH_EXPORTS="""
    export ROCM_PATH="/opt/rocm-$ROCM_VERSION"
    export ROCM_HOME="/opt/rocm-$ROCM_VERSION"
    """
    echo "$PATH_EXPORTS" >> "$VENV_PATH/bin/activate"
fi

# Activate the venv
source "$VENV_PATH/bin/activate"

# Make sure we are working with a recent version of pip and setuptools
pip install --upgrade pip
pip install --upgrade setuptools

# =============================================================================
# Building GPU support
# =============================================================================

if [ "$WITH_GPU" = "true" ]; then
    # =========================================================================
    # Install ROCm-LLVM-Python
    # =========================================================================

    # Remove any pre-existing install
    rm -rf "$ROCM_LLVM_PY_DIR"

    # Clone in the repo
    git clone https://github.com/ROCm/rocm-llvm-python "$ROCM_LLVM_PY_DIR"

    # Enter the repo
    cd $ROCM_LLVM_PY_DIR

    # Get the branch for our preferred version of ROCM
    git checkout "release/rocm-rel-$ROCM_VERSION"

    # Build the package
    ./init.sh
    sed -i "s/cimport *cpython.string/#cimport cpython.string/g" "$ROCM_LLVM_PY_DIR/rocm-llvm-python/rocm/llvm/_util/types.pyx"
    ./build_pkg.sh --post-clean -j 16

    # Select a wheel with the preferred rocm version.
    LATEST=$( ls -1 rocm-llvm-python/dist/rocm_llvm_python-${ROCM_VERSION}*.whl | tail -n 1 )
    pip install --force-reinstall $LATEST
    unset LATEST

    # =========================================================================
    # Install HIP-Python
    # =========================================================================

    pip install -i https://test.pypi.org/simple "hip-python~=$ROCM_VERSION"
    pip install -i https://test.pypi.org/simple "hip-python-as-cuda~=$ROCM_VERSION"

    # =========================================================================
    # Install HIP-Numba
    # =========================================================================

    # Install supported library versions
    pip install numba==0.60.0
    pip install cvxpy==1.7.0
    pip install scipy==1.12

    # Install HIP-Numba
    pip config set global.extra-index-url https://test.pypi.org/simple
    pip install --no-deps "git+https://github.com/ROCm/numba-hip.git@8098162162fb0babd77b56583b289d6dd6226151"

    # =============================================================================
    #  Install Harmonize
    # =============================================================================

    cd "$HARMONIZE_DIR"
    git checkout "$HARMONIZE_BRANCH"
    pip install -e .
fi

# =============================================================================
# Install MC/DC
# =============================================================================

# MC/DC
cd "$MCDC_DIR"
git checkout "$MCDC_BRANCH"
pip install -e .[dev]
