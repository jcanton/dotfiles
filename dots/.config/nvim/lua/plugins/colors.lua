if true then
    -- let's use the pre-installed colorschemes
    return {}
end

return {
    -- add gruvbox
    { "ellisonleao/gruvbox.nvim" },

    -- add tinted-vim
    { "tinted-theming/tinted-vim" },

    -- add solarized
    {
        "maxmx03/solarized.nvim",
        lazy = false,
        priority = 1000,
        ---@type solarized.config
        opts = {},
        config = function(_, opts)
            vim.o.termguicolors = true
            vim.o.background = "light"
            require("solarized").setup(opts)
            vim.cmd.colorscheme("solarized")
        end,
    },

    -- Configure LazyVim to load one (does not work?!?)
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "tokyonight-day",
        },
    },
}
