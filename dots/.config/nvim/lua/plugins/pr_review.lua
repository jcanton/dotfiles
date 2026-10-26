-- GitHub PR review in codediff.nvim (lua/pr_review): <leader>gR reviews the
-- current branch's PR, r (or <CR> <CR>) in the snacks PR picker (<leader>gp)
-- any PR.
return {
    {
        "esmuellert/codediff.nvim",
        -- pr_review hooks codediff internals: update deliberately
        tag = "v4.0.6",
        -- build the diff library here instead of downloading an unverified binary
        build = "./build.sh",
        cmd = "CodeDiff",
        init = function()
            -- same for the file watcher: codediff falls back to polling
            vim.env.CODEDIFF_WATCHER_NO_AUTO_INSTALL = "1"
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                once = true,
                callback = function()
                    require("pr_review").setup()
                end,
            })
        end,
        keys = {
            {
                "<leader>gR",
                function()
                    require("pr_review").open()
                end,
                desc = "Review PR (current branch)",
            },
        },
        opts = {
            diff = { compact = true },
            -- tree: ]f / [f walk the files in the PR file tree's order
            explorer = { view_mode = "tree", line_stats = { enabled = true } },
            -- q alone is too easy to hit: close with qq (or by holding q)
            keymaps = { view = { quit = "qq" } },
        },
        config = function(_, opts)
            require("codediff").setup(opts)
            require("pr_review").hook_codediff()
        end,
    },
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                sources = {
                    gh_pr = {
                        actions = {
                            pr_review = {
                                desc = "Review in worktree",
                                action = function(picker, item)
                                    picker:close()
                                    require("pr_review").open({ repo = item.repo, number = item.number })
                                end,
                            },
                        },
                        -- r after <Esc>; <CR> <CR> works too ("Review in worktree"
                        -- is the first entry of the action menu)
                        win = {
                            input = { keys = { ["r"] = { "pr_review", mode = "n" } } },
                            list = { keys = { ["r"] = "pr_review" } },
                        },
                    },
                },
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        opts = function(_, opts)
            table.insert(opts.sections.lualine_x, 1, {
                function()
                    return require("pr_review").statusline()
                end,
                cond = function()
                    return package.loaded.pr_review ~= nil and require("pr_review").current() ~= nil
                end,
                color = "DiagnosticInfo",
            })
        end,
    },
}
