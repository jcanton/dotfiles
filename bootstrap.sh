#!/usr/bin/env bash
#
# Link the dotfiles into $HOME. Safe to re-run, and git hooks re-run it after
# every pull, so files added to the repo get linked on every machine.
#
#   ./bootstrap.sh [--profile NAME] [--dry-run] [--no-tmux]
#
#   --profile NAME  link conditionals/NAME.links on this machine, and remember it
#   --dry-run       print what would change, change nothing
#   --no-tmux       skip installing the tmux plugins
#
# dots/ mirrors $HOME: every tracked file gets a symlink and the directories
# above it are real directories, so programs writing next to their config
# don't write into this repo. WHOLE_DIRS are linked whole instead.
#
# conditionals/<profile>.links lists per-machine links, one per line: a path
# in conditionals/, then the link's path in $HOME. The profile is the one
# remembered for this clone, else the one named after the machine: mac on
# macOS, else $CLUSTER_NAME or `hostname -s`.
#
# Whatever is in a link's way is moved to originals/<time>/, under the path it
# had in $HOME.

if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
    echo "bootstrap.sh: run it as ./bootstrap.sh, don't source it" >&2
    return 1
fi
set -euo pipefail
shopt -s nullglob

# Their programs keep gitignored state inside: lazy-lock.json, vim-plug's plugins.
WHOLE_DIRS=".config/nvim .vim"

REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
DOTS=$REPO/dots
CONDITIONALS=$REPO/conditionals
BACKUP=$REPO/originals/$(date +%Y%m%d-%H%M%S)

dry_run=false
# Directories a dry run pretends to have made, one per line.
pretend_dirs=$'\n'

die() {
    echo "bootstrap.sh: $*" >&2
    exit 1
}

run() {
    if ! $dry_run; then "$@"; fi
}

tilde() {
    # shellcheck disable=SC2088 # the ~ is only printed
    echo "~/${1#"$HOME"/}"
}

pretended() { # is $1, or a directory above it, made only by the dry run?
    local dir=$1
    while [[ $dir == "$HOME"/* ]]; do
        if [[ $pretend_dirs == *$'\n'"$dir"$'\n'* ]]; then return 0; fi
        dir=$(dirname "$dir")
    done
    return 1
}

make_dir() {
    run mkdir "$1"
    if $dry_run; then pretend_dirs+=$1$'\n'; fi
    echo "mkdir   $(tilde "$1")"
}

backup() { # move $1 to $BACKUP, under its path relative to $HOME
    local path=$1 dest=$BACKUP/${1#"$HOME"/}
    [[ $path == "$HOME"/* ]] || die "refusing to move $path, it is outside \$HOME"
    [[ ! -e $dest && ! -L $dest ]] || die "$dest already exists"
    run mkdir -p "$(dirname "$dest")"
    run mv "$path" "$dest"
    echo "backup  $(tilde "$path") -> ${dest#"$REPO"/}"
}

unfold() { # replace $1, a link to the repo directory $2, with a real directory
    local dir=$1 src=$2
    if [[ -n $(git -C "$REPO" ls-files --others -- "$src") ]]; then
        die "$(tilde "$dir") links to $src, which holds untracked files; move them out of the repo, then re-run"
    fi
    run rm "$dir"
    echo "unfold  $(tilde "$dir")"
    make_dir "$dir"
}

ensure_dir() { # make $1, in $HOME, a directory outside the repo
    local dir=$1 target
    if [[ $dir == "$HOME" ]] || pretended "$dir"; then return 0; fi
    ensure_dir "$(dirname "$dir")"
    if [[ -L $dir ]]; then
        target=$(readlink "$dir")
        if [[ ${target%/} == "$REPO"/* ]]; then unfold "$dir" "${target%/}"; fi
    elif [[ -e $dir && ! -d $dir ]]; then
        backup "$dir"
        make_dir "$dir"
    elif [[ ! -e $dir ]]; then
        make_dir "$dir"
    fi
}

place() { # symlink $2 to $1
    local src=$1 link=$2 current
    ensure_dir "$(dirname "$link")"
    if ! pretended "$link" && [[ -e $link || -L $link ]]; then
        current=$(readlink "$link" || true)
        if [[ ${current%/} == "$src" ]]; then return 0; fi
        backup "$link"
    fi
    run ln -s "$src" "$link"
    echo "link    $(tilde "$link")"
}

whole_dir() { # the entry of WHOLE_DIRS holding $1, if any
    local dir
    for dir in $WHOLE_DIRS; do
        if [[ $1 == "$dir"/* ]]; then
            echo "$dir"
            return
        fi
    done
}

link_dots() {
    local rel whole linked_whole=
    while IFS= read -r -d '' rel; do
        rel=${rel#dots/}
        if [[ ! -e $DOTS/$rel ]]; then continue; fi # deleted, not yet committed
        whole=$(whole_dir "$rel")
        if [[ -z $whole ]]; then
            place "$DOTS/$rel" "$HOME/$rel"
        elif [[ $whole != "$linked_whole" ]]; then
            place "$DOTS/$whole" "$HOME/$whole"
            linked_whole=$whole
        fi
    done < <(git -C "$REPO" ls-files -z dots)
}

link_profile() {
    local profile=$1 src link
    while read -r src link || [[ -n $src ]]; do
        case $src in '' | '#'*) continue ;; esac
        [[ -e $CONDITIONALS/$src ]] || die "$profile.links: no conditionals/$src"
        place "$CONDITIONALS/$src" "$HOME/$link"
    done <"$CONDITIONALS/$profile.links"
}

profiles() {
    local file
    for file in "$CONDITIONALS"/*.links; do
        file=${file##*/}
        printf '%s ' "${file%.links}"
    done
}

detect_profile() {
    local name
    if [[ $(uname -s) == Darwin ]]; then
        echo mac
        return
    fi
    for name in "${CLUSTER_NAME:-}" "$(hostname -s)"; do
        if [[ -n $name && -f $CONDITIONALS/$name.links ]]; then
            echo "$name"
            return
        fi
    done
}

install_hooks() { # a pull that fast-forwards runs post-merge, one that rebases post-rewrite
    local hooks hook
    hooks=$(git -C "$REPO" rev-parse --git-path hooks)
    if [[ $hooks != /* ]]; then hooks=$REPO/$hooks; fi
    for hook in post-merge post-rewrite; do
        if grep -qs 'Installed by bootstrap.sh' "$hooks/$hook"; then continue; fi
        if [[ -e $hooks/$hook ]]; then
            echo "bootstrap.sh: $hooks/$hook exists, not replacing it" >&2
            continue
        fi
        if ! $dry_run; then
            mkdir -p "$hooks"
            cat >"$hooks/$hook" <<'EOF'
#!/bin/sh
# Installed by bootstrap.sh: link what the pull added.
exec "$(git rev-parse --show-toplevel)/bootstrap.sh" --no-tmux
EOF
            chmod +x "$hooks/$hook"
        fi
        echo "hook    $hook"
    done
}

setup_tmux() { # install TPM and the plugins .tmux.conf lists
    local tpm=$HOME/.tmux/plugins/tpm
    if ! command -v tmux >/dev/null; then
        echo "bootstrap.sh: tmux not found, skipping its plugins" >&2
        return 0
    fi
    if $dry_run; then return 0; fi
    if [[ ! -e $tpm ]]; then git clone https://github.com/tmux-plugins/tpm "$tpm"; fi
    # install_plugins needs a running server: keep one up with a throwaway session
    tmux new-session -d -s __noop 2>/dev/null || true
    tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins"
    "$tpm/bin/install_plugins" || echo "bootstrap.sh: installing the tmux plugins failed" >&2
    tmux kill-session -t __noop 2>/dev/null || true
}

profile='' remember=false no_tmux=false
while (($#)); do
    case $1 in
    --profile) profile=${2:?--profile needs a name}; remember=true; shift 2 ;;
    --dry-run) dry_run=true; shift ;;
    --no-tmux) no_tmux=true; shift ;;
    *) die "unknown argument $1, see the top of bootstrap.sh" ;;
    esac
done

if $dry_run; then echo "Dry run, nothing is changed:"; fi
if [[ -z $profile ]]; then
    profile=$(git -C "$REPO" config --get bootstrap.profile || detect_profile)
fi
if [[ -n $profile && ! -f $CONDITIONALS/$profile.links ]]; then
    die "no profile $profile, have: $(profiles)"
fi
if $remember; then run git -C "$REPO" config --local bootstrap.profile "$profile"; fi

link_dots
if [[ -n $profile ]]; then
    link_profile "$profile"
else
    echo "No profile for $(hostname -s), so nothing from conditionals/ is linked. Pick one with --profile: $(profiles)"
fi
install_hooks
if ! $no_tmux; then setup_tmux; fi
