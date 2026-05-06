return {
    {
        "folke/snacks.nvim",
        keys = {
            {
                "<leader>ao",
                function()
                    Snacks.terminal("opencode " .. vim.fn.expand("%:p"), {
                        win = {
                            style = "terminal",
                            position = "right",
                        },
                    })
                end,
                desc = "OpenCode split (current file)",
            },
            {
                "<leader>aO",
                function()
                    Snacks.terminal("opencode " .. vim.fn.expand("%:p"), {
                        win = { style = "float" },
                    })
                end,
                desc = "OpenCode float (current file)",
            },
        },
    },
}
