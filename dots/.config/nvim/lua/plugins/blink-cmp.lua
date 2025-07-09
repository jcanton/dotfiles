return {
    "saghen/blink.cmp",

    opts = function(_, opts)
        vim.b.completion = true

        Snacks.toggle({
            name = "Completion",
            get = function()
                return vim.b.completion
            end,
            set = function(state)
                vim.b.completion = state
            end,
        }):map("<leader>uk")

        opts.enabled = function()
            return vim.b.completion ~= false
        end

        opts.completion = opts.completion or {}
        opts.completion.ghost_text = {
            enabled = false, -- default: vim.g.ai_cmp,
        }
        opts.completion.list = opts.completion.list or {}
        opts.completion.list.selection = {
            -- preselect = false, -- Do not preselect
            auto_insert = false, -- Do not auto insert
        }

        opts.sources = opts.sources or {}
        opts.sources.providers = opts.sources.providers or {}
        opts.sources.providers.buffer = opts.sources.providers.buffer or {}
        opts.sources.providers.buffer = {
            min_keyword_length = 8,
            max_items = 5,
        }

        opts.sources.keymap = opts.sources.keymap or {}
        opts.keymap = {
            -- default:
            preset = "enter",
            ["<C-y>"] = { "select_and_accept" },
            -- super tab:
            -- preset = "super-tab",
            -- ["<Right>"] = { "accept", "fallback" },
        }

        return opts
    end,
    opts_extend = { "sources.default" },
}
