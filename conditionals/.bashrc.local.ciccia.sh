# ciccia (Synology DSM) specific settings

# DSM has no package manager. nvim and uv are release tarballs unpacked in
# ~/.local/opt and linked into ~/.local/bin; to upgrade, unpack the new one
# over the old. rg, fd, fzf, lazygit, tree-sitter, gcc and node come from a
# micromamba env, last in PATH so DSM's own tools come first; to upgrade:
#   ~/micromamba/bin/micromamba update -p ~/micromamba/envs/tools --all
export PATH="$PATH:$HOME/micromamba/envs/tools/bin"
