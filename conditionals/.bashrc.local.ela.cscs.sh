# CSCS specific settings:

alias sc='cd $SCRATCH'

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

. "$HOME/.cargo/env"

if [ -n "${VSCODE_INVOKING}" ]; then
    #echo "invoked by vscode"
    # set colors
    export CLICOLOR=1
    # Base16 Shell
    #source $HOME/projects/tinted-shell/scripts/base16-solarized-light.sh
fi


alias sq='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
alias sql='squeue -u jcanton -o "%.8i %.8u %.7a %.9P %.70j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E"'
function wsq {
    watch -n 1 "squeue -u jcanton -o '%.8i %.8u %.7a %.9P %.30j %.8T %.13S %.10M %.10L %.6D %.5C %.11r %E'"
}

export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT

case $HOSTNAME in
balfrin*)
    export GT4PY_BUILD_CACHE_DIR=$SCRATCH/gt4py_cache
    # configure the user-environment (uenv) utility
    # source /users/jcanton/.local/bin/activate-uenv
    #if uenv status | grep -q 'no uenv loaded'; then
    #    uenv start --view=icon-wcp:icon /scratch/mch/leclairm/uenvs/images/icon.v1.rc4.sqfs
    #fi
    loadUenv() {
        uenv start --view=icon-wcp:icon /scratch/mch/leclairm/uenvs/images/icon.v1.rc4.sqfs
    }
    ;;
santis*)
    export VIMRUNTIME=/users/jcanton/.local/repo/neovim/runtime
    export GT4PY_BUILD_CACHE_DIR=$SCRATCH/gt4py_cache
    ;;
ela?)
    echo "We're on ela"
    # Though ela does not have access to /project anymore...
    ;;
*)
    echo "hostname not recognized in .bashrc.local"
    ;;
esac
