# pi specific settings:

# Snap packages (damn alacritty)
export PATH="$PATH:/snap/bin"

export TERMINAL="alacritty"


# Colors
export CLICOLOR=1
#source $HOME/projects/tinted-shell/scripts/base16-tokyo-night-terminal-light.sh

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
export GT4PY_BUILD_CACHE_DIR=/home/jcanton/projects/

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

set_brightness() {
    brightness_value=$1
    command="ddcutil --display 1 setvcp 10 ${brightness_value}"
    eval $command
}

set_resolution() {
    resolution_value=$1
    command="xrandr --output HDMI-1 --mode ${resolution_value}"
    eval $command
}
