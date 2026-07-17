# mac specific settings:

export BASH_SILENCE_DEPRECATION_WARNING=1

export CLUSTER_NAME="mac"

# Base16 Shell
export CLICOLOR=1
# source $HOME/projects/tinted-shell/scripts/base16-tokyo-night-terminal-storm.sh

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
#export GT4PY_BUILD_CACHE_DIR=/Users/jcanton/projects/

# # gcc from homebrew for icon4py
# export CC=gcc-15
# export CXX=g++-15

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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

# shell integrations for iterm2
test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

export MORPH_API_KEY="sk-Zlpc1IPv7RC2K_pO_2l4leTPX0uVHTK2294we5SJKl3zsnQE"

# >>> claude-auto-retry >>>
# Drop any pre-existing `claude` alias (Claude Code's own installer adds one)
# before defining the wrapper function. Without this, the shell expands the
# alias while parsing `claude() {`, producing "syntax error near unexpected
# token '('" when the rc file is sourced.
unalias claude 2>/dev/null || true
claude() {
  if [ "${CLAUDE_AUTO_RETRY_ACTIVE}" = "1" ]; then
    command claude "$@"
    return $?
  fi
  export CLAUDE_AUTO_RETRY_ACTIVE=1
  local _car_old_int_trap _car_old_term_trap
  _car_old_int_trap=$(trap -p INT)
  _car_old_term_trap=$(trap -p TERM)
  trap 'unset CLAUDE_AUTO_RETRY_ACTIVE' INT TERM
  node "/opt/homebrew/lib/node_modules/claude-auto-retry/src/launcher.js" "$@"
  local _car_exit=$?
  unset CLAUDE_AUTO_RETRY_ACTIVE
  # Restore previous traps instead of clobbering them
  eval "${_car_old_int_trap:-trap - INT}"
  eval "${_car_old_term_trap:-trap - TERM}"
  return $_car_exit
}
# <<< claude-auto-retry <<<
