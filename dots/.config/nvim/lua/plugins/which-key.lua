return {
    "folke/which-key.nvim",
    opts = function(_, opts)
        opts.icons = {
            rules = {
                { pattern = "opencode", icon = "󱙺", color = "cyan" },
                { pattern = "slime", icon = "", color = "red" },
                { pattern = "undotree", icon = "", color = "red" },
            },
        }
    end,
}
