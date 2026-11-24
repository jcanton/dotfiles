# mac specific settings:

export BASH_SILENCE_DEPRECATION_WARNING=1

export CLUSTER_NAME="mac"

alias ciccia_org_music="ssh -t ciccia sudo /usr/local/bin/docker exec -it -u abc beets beet import /music"

# Base16 Shell
export CLICOLOR=1
# source $HOME/projects/tinted-shell/scripts/base16-tokyo-night-terminal-storm.sh

# gt4py
export GT4PY_BUILD_CACHE_LIFETIME=PERSISTENT
#export GT4PY_BUILD_CACHE_DIR=/Users/jcanton/projects/

# # gcc from homebrew for icon4py
# export CC=gcc-15
# export CXX=g++-15

export PATH=/opt/homebrew/share/google-cloud-sdk/bin:$PATH
source $HOME/.bashrc.local.private

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Skim
alias skim="/Applications/Skim.app/Contents/MacOS/Skim"

# Vorssaint: share settings between Macs through conditionals/vorssaint.settings.
# vorssaint-save exports this Mac's settings into the repo (commit and push them);
# vorssaint-load replaces this Mac's settings with the file and restarts the app.
_vorssaint_bin=/Applications/Vorssaint.app/Contents/MacOS/Vorssaint
_vorssaint_file() {
    local dotfiles
    dotfiles=$(readlink ~/.functions)
    echo "${dotfiles%/dots/.functions}/conditionals/vorssaint.settings"
}
vorssaint-save() {
    local file
    file=$(_vorssaint_file)
    "$_vorssaint_bin" --export-settings "$file" || return
    # The export writes JSON-in-string values with random key order; sort the keys
    # so an unchanged setup gives an unchanged file.
    python3 -I - "$file" <<'EOF'
import json, plistlib, sys
path = sys.argv[1]
with open(path, "rb") as f:
    backup = plistlib.load(f)
for key, value in backup["settings"].items():
    if isinstance(value, str) and value.startswith("{"):
        try:
            backup["settings"][key] = json.dumps(json.loads(value), sort_keys=True, separators=(",", ":"))
        except ValueError:
            pass
with open(path, "wb") as f:
    plistlib.dump(backup, f, sort_keys=True)
EOF
    git -C "${file%/conditionals/*}" status --short -- "$file"
}
vorssaint-load() {
    # The import refuses to run while the app is open.
    osascript -e 'quit app "Vorssaint"' || return
    while pgrep -qx Vorssaint; do sleep 0.2; done
    "$_vorssaint_bin" --import-settings "$(_vorssaint_file)" || return
    open -a Vorssaint
}

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

# iTerm2: arrow mouse pointer instead of I-beam (OSC 22). Outside tmux only:
# tmux swallows it, but the pointer set by the outer shell survives into tmux.
[[ $TERM_PROGRAM == iTerm.app ]] && printf '\e]22;left_ptr\e\\'

# >>> icon4py dev scripts >>>
# The scripts/* shebang uses "uv run --isolated", which rebuilds a throwaway
# environment on every call (~4s). Invoking uv ourselves bypasses it (~0.3s).
# See C2SM/icon4py#1419.
_i4_run() {
    local entry=$1
    shift
    local root venv
    root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "i4: not in a git repo" >&2
        return 1
    }
    [ -f "$root/$entry" ] || {
        echo "i4: no $entry in $root" >&2
        return 1
    }
    venv="$root/.venv/bin/python"
    # Pin to the venv's own interpreter: without this uv follows .python-version and
    # deletes/rebuilds a venv that was created with a different python.
    if [ -x "$venv" ]; then
        (cd "$root" && UV_PYTHON="$venv" uv run -q --frozen --group scripts python3 "$entry" "$@")
    else
        (cd "$root" && uv run -q --frozen --group scripts python3 "$entry" "$@")
    fi
}
i4() { _i4_run scripts/run "$@"; } # e.g. i4 inspect-savepoints savepoints -e exclaim_ape_aesPhys
i4t() { _i4_run scripts/test "$@"; }
# <<< icon4py dev scripts <<<
