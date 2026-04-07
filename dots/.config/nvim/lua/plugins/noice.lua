return {
    "folke/noice.nvim",
    opts = {
        routes = {
            {
                -- hide lsp progress messages, as they tend to spam a lot
                filter = {
                    event = "lsp",
                    kind = "progress",
                },
                opts = { skip = true },
            },
        },
    },
}
