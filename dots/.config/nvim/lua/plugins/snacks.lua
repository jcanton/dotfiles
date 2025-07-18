return {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
    dashboard = {
            sections = {
                { section = "header" },
                { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                { section = "startup" },
            },
    },
        -- try neo-tree and telescope
        -- picker = {
        --     sources = {
        --         -- explorer picker configuration
        --         explorer = {
        --             win = {
        --                 list = {
        --                     keys = {
        --                         ["o"] = "confirm", -- remap
        --                     },
        --                 },
        --             },
        --         },
        --         -- file picker configuration
        --         files = {
        --             -- search hidden files too
        --             hidden = true,
        --             win = {
        --                 input = {
        --                     keys = {
        --                         ["H"] = "toggle_hidden",
        --                     },
        --                 },
        --             },
        --         },
        --         -- grep picker configuration
        --         grep = {
        --             -- search hidden files too
        --             hidden = true,
        --             win = {
        --                 input = {
        --                     keys = {
        --                         ["H"] = "toggle_hidden",
        --                     },
        --                 },
        --             },
        --         },
        --     },
        -- },
    },
    -- keys = {
    --     -- stylua: ignore
    --     { "<leader><space>", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)", },
    -- },
}
