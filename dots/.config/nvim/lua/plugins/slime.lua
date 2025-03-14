return {
    -- slime (REPL integration)
    "jpalardy/vim-slime",
    keys = {
        { "<leader>rc", "<cmd>SlimeConfig<cr>", desc = "Slime Config" },
        { "<leader>rr", "<Plug>SlimeSendCell<BAR>/^# %%<CR>", desc = "Slime Send Cell" },
        { "<leader>rr", ":<C-u>'<,'>SlimeSend<CR>", mode = "v", desc = "Slime Send Selection" },
    },
    config = function()
        vim.g.slime_target = "tmux"
        vim.g.slime_cell_delimiter = "# %%"
        vim.g.slime_bracketed_paste = 1
        --vim.slime_default_config = {'socket_name': get(split($TMUX, ','), 0), 'target_pane': '.2' }
        --vim.g.slime_dont_ask_default = 0
    end,
}
