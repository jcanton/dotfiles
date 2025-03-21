# CSCS specific settings:

alias sc='cd $SCRATCH'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

if [ -n "${VSCODE_INVOKING}" ]; then
    #echo "invoked by vscode"
    # set colors
    export CLICOLOR=1
    # Base16 Shell
    source $HOME/projects/tinted-shell/scripts/base16-solarized-light.sh
fi
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT

export OMP_NUM_THREADS=12
alias sq='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
alias sql='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.50j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
function wsq {
    watch -n 1 "squeue -u jcanton -o '%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E'"
}

case $HOSTNAME in
    balfrin*)
        export GT4PY_BUILD_CACHE_DIR=$SCRATCH/gt4py_cache
        # configure the user-environment (uenv) utility
        # source /users/jcanton/.local/bin/activate-uenv
        #if uenv status | grep -q 'no uenv loaded'; then
        #    uenv start --view=icon-wcp:icon /scratch/mch/leclairm/uenvs/images/icon.v1.rc4.sqfs
        #fi
        ;;
    nid*)
        alias pyNode='source ~/.pythonComputeNode.env'
        ;;
    ela?)
        echo "We're on ela"
        # Though ela does not have access to /project anymore...
        ;;
    *)
        echo "hostname not recognized in .bashrc.local"
        ;;
esac

loadUenv() {
    # configure the user-environment (uenv) utility
    #source /users/jcanton/.local/bin/activate-uenv
    uenv start --view=icon-wcp:icon /scratch/mch/leclairm/uenvs/images/icon.v1.rc4.sqfs
    #uenv start /scratch/mch/leclairm/uenvs/images/icon.v1.rc4.sqfs
    #uenv view icon-wcp:icon
}

# # PALM
# export LD_LIBRARY_PATH="/store/g142/jcanton/repos/palm_build/rrtmg/lib:${LD_LIBRARY_PATH}"
# export PATH="/store/g142/jcanton/repos/palm_build/bin:${PATH}"

# # MCH stuff
# # source /users/osm/.opr_setup_dir
# # export PATH=$OPR_SETUP_DIR/bin:$PATH
# # export MODULEPATH=$MODULEPATH\:$OPR_SETUP_DIR/modules/modulefiles
# ulimit -s unlimited # for not getting segmentation faults
# export OMP_STACKSIZE=500M
# export OMP_PLACES=sockets
# export OMP_PROC_BIND="spread,close,close"
# export PATH="/project/s83c/fieldextra/daint/bin:$PATH"
# export PATH="/project/s83c/fieldextra/daint/tools:$PATH"
# alias fieldextra='/project/s83c/fieldextra/daint/bin/fieldextra_gnu_opt_omp'
# alias grins='/project/s83c/fieldextra/daint/tools/grins'
