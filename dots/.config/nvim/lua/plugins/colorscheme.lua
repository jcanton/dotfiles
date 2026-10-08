-- Alternatives stay lazy: lazy.nvim loads them on `:colorscheme <name>`.
return {
    -- add gruvbox
    { "ellisonleao/gruvbox.nvim", lazy = true },

    -- add catppuccin
    -- Not lazy: nvim >= 0.12 ships its own `catppuccin`, which would shadow this one.
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 1000,
        lazy = false,
        opts = {
            -- configurations
            flavour = "frappe",
        },
    },

    -- add nightfox
    { "EdenEast/nightfox.nvim", lazy = true },

    -- add solarized
    { "shaunsingh/solarized.nvim", lazy = true },
    -- { "ishan9299/nvim-solarized-lua" },

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight-day",
        },
    },
}
