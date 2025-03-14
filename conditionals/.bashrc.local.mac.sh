# mac specific settings:

export BASH_SILENCE_DEPRECATION_WARNING=1

# Base16 Shell
export CLICOLOR=1
source $HOME/projects/tinted-shell/scripts/base16-tokyo-night-terminal-storm.sh
# iTerm actually gets its colors from profiles, this is here for terminal

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
export GT4PY_BUILD_CACHE_DIR=/home/jcanton/projects/

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Skim
alias skim="/Applications/Skim.app/Contents/MacOS/Skim"

# homebrew "new" location
if [ -d "/opt/homebrew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    # and java
    export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
    export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"
else
    export PATH="/usr/local/opt/openjdk/bin:$PATH"
fi
