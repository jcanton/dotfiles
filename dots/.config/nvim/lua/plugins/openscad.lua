return {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            -- Mason builds openscad-lsp with cargo, so it needs `brew install rust`;
            -- without cargo (ciccia) skip it, or Mason retries on every start.
            openscad_lsp = {
                enabled = vim.fn.executable("cargo") == 1,
                cmd = { "openscad-lsp", "--stdio", "--indent", "    " },
            },
        },
    },
}
