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

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "catppuccin",
        },
    },
}
