alias sq='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
alias sc='cd $SCRATCH'
export PROJECT="/capstor/store/cscs/userlab/cwd01/jcanton"
alias pr='cd $PROJECT'

alias l="ls -F"
alias la="ls -lFh"
alias ll="ls -lAFh"
alias lsd="ls -lF | grep --color=never '^d'"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias g="git"

shopt -s extglob
shopt -s globstar

# # manual uenv
# export PATH=$HOME/.local/$(uname -m)/bin:$PATH
# unset -f uenv
# loadUenv() {
#     uenv start prgenv-gnu --view default
# }

# # ufficial uenv
# uenv image pull icon/25.2:v3
loadUenv() {
    uenv start --view default icon/25.2:v4
}

# activate / deactivate virtual environment
function va() {
    if [ -n "$1" ]; then
        source "./$1/.venv/bin/activate"
    else
        source .venv/bin/activate
    fi
}
function vd() {
    deactivate
}

#export GT4PY_BUILD_CACHE_DIR=/capstor/scratch/cscs/jcanton/gt4py_cache/

function buildIcon4py() {
    export PYTHONOPTIMIZE=2
    export GHEX_USE_GPU=ON
    export GHEX_GPU_TYPE=NVIDIA
    export GHEX_GPU_ARCH="80;90"
    export GHEX_TRANSPORT_BACKEND=MPI
    export MPICH_CXX=$(which g++)
    export MPICH_CC=$(which gcc)
    export MPICH_GPU_SUPPORT_ENABLED=1
}
export GT4PY_BUILD_CACHE_LIFETIME=persistent
export GT4PY_UNSTRUCTURED_HORIZONTAL_HAS_UNIT_STRIDE=1

export LD_LIBRARY_PATH=/user-environment/linux-sles15-neoverse_v2/gcc-13.2.0/nvhpc-25.1-tsfur7lqj6njogdqafhpmj5dqltish7t/Linux_aarch64/25.1/compilers/lib:$LD_LIBRARY_PATH

export ICON4PY_ENABLE_TESTDATA_DOWNLOAD=false
#uv sync --no-binary-package mpi4py --extra all --extra distributed --extra cuda12 --python $(which python) --refresh


# building icon4py
# GHEX_USE_GPU=ON GHEX_GPU_TYPE=NVIDIA GHEX_GPU_ARCH=90
# GHEX_TRANSPORT_BACKEND=MPI MPICH_CXX=$(which g++) MPICH_CC=$(which gcc) uv
# sync --no-binary-package mpi4py --extra all --extra distributed --extra
# cuda12 --python $(which python) --no-cache
