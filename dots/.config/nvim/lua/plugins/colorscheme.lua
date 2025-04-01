return {
    -- add gruvbox
    { "ellisonleao/gruvbox.nvim" },

    -- add catppuccin
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
    { "EdenEast/nightfox.nvim" },

    -- add solarized
    { "shaunsingh/solarized.nvim" },
    -- { "ishan9299/nvim-solarized-lua" },

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "dayfox",
        },
    },
}
