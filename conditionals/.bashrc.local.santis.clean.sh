alias sq='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
alias sc='cd $SCRATCH'
alias l="ls -F"
alias la="ls -lFh"
alias ll="ls -lAFh"
alias lsd="ls -lF | grep --color=never '^d'"

# # manual uenv
# export PATH=$HOME/.local/$(uname -m)/bin:$PATH
# unset -f uenv
# loadUenv() {
#     uenv start prgenv-gnu --view default
# }

# # ufficial uenv
# uenv image pull icon/25.2:v3
loadUenv() {
    uenv start --view default icon/25.2:v3
}

export PYTHONOPTIMIZE=2
export GT4PY_UNSTRUCTURED_HORIZONTAL_HAS_UNIT_STRIDE=1
export GT4PY_BUILD_CACHE_LIFETIME=persistent
export GT4PY_BUILD_CACHE_DIR=/capstor/scratch/cscs/jcanton/gt4py_cache/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/user-environment/linux-sles15-neoverse_v2/gcc-13.2.0/nvhpc-25.1-tsfur7lqj6njogdqafhpmj5dqltish7t/Linux_aarch64/25.1/compilers/lib
