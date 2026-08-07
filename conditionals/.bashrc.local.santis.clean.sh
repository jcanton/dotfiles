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

# # ufficial uenv
# uenv image pull icon/26.7:v1
loadUenv() {
    uenv start --view default icon/26.7:v1
}

# GT4Py emits UTF-8 identifiers (e.g. z_ifvᐞ0). CMake takes the compiler from CXX,
# else the first c++ on PATH, which here is an old /usr/bin/c++ that rejects them with
# "stray '\341' in program". Point it at the uenv compiler instead.
# NOTE: after changing this, delete .gt4py_cache -- GT4Py caches a prototype
# compile_commands.json and replays the old compiler command verbatim.
useUenvCompilers() {
    local cxx
    cxx=$(command -v g++) || return 0
    case "$cxx" in
        /usr/bin/*) return 0 ;;   # system compiler, too old: leave CXX unset
    esac
    export CXX="$cxx"
    export CC="$(command -v gcc)"
}
useUenvCompilers

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
    useUenvCompilers
    uv sync --no-binary-package mpi4py --extra all --extra distributed --extra cuda12 --python $(which python) --refresh --group scripts
}
export GT4PY_BUILD_CACHE_LIFETIME=persistent
export GT4PY_UNSTRUCTURED_HORIZONTAL_HAS_UNIT_STRIDE=1

export LD_LIBRARY_PATH=/user-environment/linux-sles15-neoverse_v2/gcc-13.2.0/nvhpc-25.1-tsfur7lqj6njogdqafhpmj5dqltish7t/Linux_aarch64/25.1/compilers/lib:$LD_LIBRARY_PATH

export ICON4PY_ENABLE_TESTDATA_DOWNLOAD=false

# >>> icon4py dev scripts >>>
# The scripts/* shebang uses "uv run --isolated", which rebuilds a throwaway
# environment on every call (~4s). Invoking uv ourselves bypasses it (~0.3s).
# See C2SM/icon4py#1419.
_i4_run() {
    local entry=$1; shift
    local root venv
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "i4: not in a git repo" >&2; return 1; }
    [ -f "$root/$entry" ] || { echo "i4: no $entry in $root" >&2; return 1; }
    venv="$root/.venv/bin/python"
    # Pin to the venv's own interpreter: without this uv follows .python-version and
    # deletes/rebuilds a venv that was created with a different python.
    if [ -x "$venv" ]; then
        ( cd "$root" && UV_PYTHON="$venv" uv run -q --frozen --group scripts python3 "$entry" "$@" )
    else
        ( cd "$root" && uv run -q --frozen --group scripts python3 "$entry" "$@" )
    fi
}
i4()  { _i4_run scripts/run  "$@"; }   # e.g. i4 inspect-savepoints savepoints -e exclaim_ape_aesPhys
i4t() { _i4_run scripts/test "$@"; }
# <<< icon4py dev scripts <<<
