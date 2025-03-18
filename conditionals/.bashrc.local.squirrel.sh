export OMP_NUM_THREADS=8

export SCRATCH=/scratch/l_jcanton

export HTTP_PROXY=proxy.ethz.ch:3128
export HTTPS_PROXY=proxy.ethz.ch:3128
export FTP_PROXY=proxy.ethz.ch:3128
export NO_PROXY="localhost,127.0.0.1,::1"

if [ -n "${VSCODE_INVOKING}" ]; then
    #echo "invoked by vscode"
    # set colors
    export CLICOLOR=1
    # Base16 Shell
    source $HOME/projects/tinted-shell/scripts/base16-solarized-light.sh
fi

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
export GT4PY_BUILD_CACHE_DIR=$SCRATCH

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion
