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
