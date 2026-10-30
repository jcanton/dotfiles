return {
    "nvim-treesitter/nvim-treesitter",
    opts = {
        ensure_installed = { "fortran" },
        -- its indentexpr puts gq/gw list continuations at column 0, autoindent
        -- keeps them under the item's text (after/ftplugin/markdown.lua)
        indent = { disable = { "markdown" } },
    },
}
