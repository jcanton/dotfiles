return {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
        picker = {
            sources = {
                -- explorer picker configuration
                explorer = {
                    win = {
                        list = {
                            keys = {
                                ["o"] = "confirm", -- remap
                            },
                        },
                    },
                },
                -- file picker configuration
                files = {
                    -- search hidden files too
                    hidden = true,
                    win = {
                        input = {
                            keys = {
                                ["H"] = "toggle_hidden",
                            },
                        },
                    },
                },
                -- grep picker configuration
                grep = {
                    -- search hidden files too
                    hidden = true,
                    win = {
                        input = {
                            keys = {
                                ["H"] = "toggle_hidden",
                            },
                        },
                    },
                },
            },
        },
    },
}
