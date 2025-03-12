# pi specific settings:

# Base16 Shell
export CLICOLOR=1
source $HOME/projects/dotfiles/base16/base16-solarized-light.sh

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
export GT4PY_BUILD_CACHE_DIR=/home/jcanton/projects/

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

set_brightness() {
    brightness_value=$1
    command="ddcutil --display 1 setvcp 10 ${brightness_value}"
    eval $command
}
