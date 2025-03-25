return {
    -- slime (REPL integration)
    "jpalardy/vim-slime",
    keys = {
        { "<leader>j", desc = "Slime", mode = { "v", "n" } },
        { "<leader>jc", vim.cmd.SlimeConfig, desc = "Slime Config" },
        -- { "<leader>rr", "<Plug>SlimeSendCell<BAR>/^# %%<CR>", desc = "Slime Send Cell" },
        { "<leader>jj", ":<C-u>'<,'>SlimeSend<CR>", mode = "v", desc = "Slime Send Selection" },
    },
    config = function()
        local tmux = os.getenv("TMUX")
        local socket_name = tmux and vim.split(tmux, ",")[1] or ""
        vim.g.slime_target = "tmux"
        vim.g.slime_cell_delimiter = "# %%"
        vim.g.slime_bracketed_paste = 1
        vim.g.slime_default_config = { socket_name = socket_name, target_pane = ".2" }
        --vim.g.slime_dont_ask_default = 0
    end,
}
