# AGENTS.md

Quick-start context for AI agents working in this dotfiles repo.

## What this repo is

A shell-script-based dotfiles manager. `bootstrap.sh` symlinks the files tracked in `dots/` into `$HOME`. No stow, chezmoi, or bare-git tricks.

## Key commands

| Task | Command |
|---|---|
| Install / re-link dotfiles | `./bootstrap.sh` (executed, never sourced; `--dry-run` previews) |
| Update | `dotsync` (in `.functions`) pulls this repo and agent-config; the post-merge/post-rewrite hooks bootstrap installs re-run `bootstrap.sh --links-only` and agent-config's `install.sh --force` |
| Install Homebrew packages | `bash do_not_move/brew.sh` (manual, one-time; not called by bootstrap) |

## Directory layout

- `dots/` — mirrors `$HOME`: each **tracked** file gets a symlink, the directories above it are real directories. `.config/nvim` and `.vim` are linked whole (`WHOLE_DIRS` in `bootstrap.sh`). A new file is linked only once it is committed.
- `conditionals/` — machine-specific configs. `<profile>.links` lists `source target` pairs (source in `conditionals/`, target in `$HOME`). The profile is `mac` on macOS, else `$CLUSTER_NAME` or `hostname -s`, or the one set once with `--profile NAME` (stored as `bootstrap.profile` in the clone's git config).
- `do_not_move/` — scripts that should never be symlinked
- `../agent-config/` — separate repo (Claude Code skills, agents, settings) that bootstrap clones next to this one and links with its own `install.sh`; it gets `rebase.autoStash` because Claude Code edits `settings.json` in place. The global `~/.claude/CLAUDE.md` lives here instead, in `dots/.claude/`.

## Bootstrap quirks

- When bootstrap displaces an existing file it moves it to `originals/<time>/` under its path in `$HOME` (gitignored; older runs left `originals_YYYYMMDD/`).
- It refuses to replace an old whole-directory link whose repo directory holds untracked files; move them out first.
- `com.googlecode.iterm2.plist` is at the repo root but is **not** bootstrapped — point to it manually from iTerm2 preferences.
- `conditionals/.macos` is a script to run by hand; `conditionals/iTerm/` is not linked by any profile.

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

## Opencode config

Configs live in `dots/.config/opencode/`:

| File | Symlinks to |
|------|------------|
| `opencode.json` | `~/.config/opencode/opencode.json` (via bootstrap) |
| `tui.json` | `~/.config/opencode/tui.json` (via bootstrap) |
| `package.json` | `~/.config/opencode/package.json` (via bootstrap) |

`bun.lock` and `node_modules/` stay in `~/.config/opencode/` — not managed by dotfiles. After bootstrap, run:

```bash
cd ~/.config/opencode && bun install
```

## Gitignored paths (don't create or commit these)

`originals_*/`, `dots/.vim/autoload`, `dots/.vim/plugged`, `dots/.tmux/plugins`, `lazy-lock.json`

## No CI, no tests, no pre-commit hooks
