return {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
        dashboard = {
            preset = {
                header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝]],
            },
            sections = {
                { section = "header" },
                { icon = " ", title = "Keymaps", section = "keys", indent = 2, padding = 1 },
                { icon = " ", title = "Projects", section = "projects", indent = 2, padding = 1 },
                { section = "startup" },
            },
        },
        lazygit = {
            -- lazygit writes its final directory here on quit, see autocmds.lua
            env = { LAZYGIT_NEW_DIR_FILE = vim.fn.stdpath("state") .. "/lazygit-new-dir" },
        },
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
                -- notification history (<leader>n): y / <c-y> copies the
                -- message to the clipboard
                notifications = {
                    actions = {
                        yank_msg = function(picker, item)
                            if item then
                                vim.fn.setreg("+", item.item.msg)
                                picker:close()
                                Snacks.notify("Copied the notification to the clipboard")
                            end
                        end,
                    },
                    win = {
                        input = { keys = { ["<c-y>"] = { "yank_msg", mode = { "i", "n" } }, ["y"] = "yank_msg" } },
                        list = { keys = { ["y"] = "yank_msg" } },
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
    -- keys = {
    --     -- stylua: ignore
    --     { "<leader><space>", function() Snacks.picker.git_files() end, desc = "Find Files (git-files)", },
    -- },
}
