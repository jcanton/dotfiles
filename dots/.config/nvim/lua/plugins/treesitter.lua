return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        ensure_installed = { "fortran" },
        -- for gq/gw list continuations, see after/ftplugin/markdown.lua
        indent = { disable = { "markdown" } },
    },
}
