export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
export GT4PY_BUILD_CACHE_DIR=/capstor/scratch/cscs/jcanton/gt4py_cache/
export PATH=$HOME/.local/$(uname -m)/bin:$PATH
unset -f uenv
loadUenv() {
    uenv start prgenv-gnu --view default
}
