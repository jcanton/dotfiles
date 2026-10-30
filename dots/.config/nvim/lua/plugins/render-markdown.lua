return {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
        -- also in insert mode, where only the cursor line is shown raw
        -- (anti_conceal), as treesitter's conceal does for `code`
        render_modes = true,
        -- turned off (<leader>um, <leader>uc) it shows the raw text, instead of
        -- treesitter still concealing backticks and link targets
        win_options = { conceallevel = { default = 0 } },
    },
}
