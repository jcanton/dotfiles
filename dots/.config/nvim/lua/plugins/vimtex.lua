return {
    "lervag/vimtex",
    lazy = false, -- lazy-loading will disable inverse search
    config = function()
        vim.g.vimtex_mappings_disable = { ["n"] = { "K" } } -- disable `K` as it conflicts with LSP hover
        vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
        vim.g.vimtex_view_method = "skim"
    end,
    init = function()
        vim.g.vimtex_compiler_latexmk = {
            options = {
                "-verbose",
                "-file-line-error",
                "-synctex=1",
                "-interaction=nonstopmode",
                "-shell-escape",
            },
        }
    end,
    keys = {
        { "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
        { "<localLeader>ll", "<ESC>:w<CR><cmd>VimtexCompileSS<cr>", desc = "vimtex-compileSS", ft = "tex" },
    },
}
