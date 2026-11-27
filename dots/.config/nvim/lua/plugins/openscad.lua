return {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            -- Mason builds openscad-lsp with cargo, so it needs `brew install rust`
            openscad_lsp = {
                cmd = { "openscad-lsp", "--stdio", "--indent", "    " },
            },
        },
    },
}
