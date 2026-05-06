# AGENTS.md

Quick-start context for AI agents working in this dotfiles repo.

## What this repo is

A shell-script-based dotfiles manager. `bootstrap.sh` symlinks everything in `dots/` into `$HOME`. No stow, chezmoi, or bare-git tricks.

## Key commands

| Task | Command |
|---|---|
| Install / re-link dotfiles | `source bootstrap.sh` (must be **sourced**, not executed) |
| Update after `git pull` | Nothing — symlinks are live; changes take effect immediately |
| Install Homebrew packages | `bash do_not_move/brew.sh` (manual, one-time; not called by bootstrap) |

## Directory layout

- `dots/` — every file here is symlinked 1-to-1 into `$HOME` by bootstrap
- `conditionals/` — machine-specific configs (`.bashrc.local.*.sh`, `.macos`, alacritty, i3, iTerm, SSH); linked **interactively** at bootstrap time (user is prompted for each target name)
- `do_not_move/` — scripts that should never be symlinked; currently only `brew.sh`

## Bootstrap quirks

- `conditionals/` items require an interactive `read` prompt during bootstrap — they are **not** auto-linked. Each needs a target filename supplied by the user.
- When bootstrap displaces an existing file it moves it to `originals_YYYYMMDD/` (gitignored).
- `com.googlecode.iterm2.plist` is at the repo root but is **not** bootstrapped — point to it manually from iTerm2 preferences.

## Shell config chain

`.bash_profile` → `.bashrc` → sources `~/.path`, `~/.exports`, `~/.aliases`, `~/.functions`, `~/.bash_prompt`, `~/.extra`, `~/.bashrc.local`

- `~/.path` — extend `$PATH`; not committed
- `~/.extra` — secrets / per-machine overrides; not committed
- `~/.bashrc.local` — symlinked from `conditionals/.bashrc.local.*.sh` at bootstrap

## Neovim (LazyVim)

- Config lives in `dots/.config/nvim/`
- Plugin specs: `dots/.config/nvim/lua/plugins/`
- Lua formatter config: `dots/.config/nvim/stylua.toml`
- `lazy-lock.json` is gitignored

## Tmux

- Prefix remapped to `C-a`
- TPM plugins directory (`dots/.tmux/plugins/`) is gitignored
- Color theme reads `$JC_COLOR*` env vars — must be exported before tmux starts (set in `.bashrc.local` per machine)

## Gitignored paths (don't create or commit these)

`originals_*/`, `dots/.vim/autoload`, `dots/.vim/plugged`, `dots/.tmux/plugins`, `lazy-lock.json`

## No CI, no tests, no pre-commit hooks
