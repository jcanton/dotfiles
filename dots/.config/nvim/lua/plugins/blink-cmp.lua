return {
    "saghen/blink.cmp",

    opts = function(_, opts)
        -- Off by default here; <leader>uk still toggles per buffer.
        -- Snacks picker inputs are prompt buffers, which blink already skips.
        local disabled_filetypes = { "gitcommit", "gitrebase" }

        local function enabled()
            if vim.b.completion ~= nil then
                return vim.b.completion
            end
            return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
        end

        Snacks.toggle({
            name = "Completion",
            get = enabled,
            set = function(state)
                vim.b.completion = state
            end,
        }):map("<leader>uk")

        opts.enabled = enabled

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

        return opts
    end,
    opts_extend = { "sources.default" },
}
