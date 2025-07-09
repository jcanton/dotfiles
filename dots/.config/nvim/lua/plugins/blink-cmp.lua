return {
    "saghen/blink.cmp",
    -- optional: provides snippets for the snippet source
    dependencies = { "rafamadriz/friendly-snippets" },

    -- use a release tag to download pre-built binaries
    version = "*",
    -- AND/OR build from source, requires nightly: https://rust-lang.github.io/rustup/concepts/channels.html#working-with-nightly-rust
    -- build = 'cargo build --release',
    -- If you use nix, you can build from source using latest nightly rust with:
    -- build = 'nix run .#build-plugin',

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        completion = {
            ghost_text = {
                enabled = false, -- default: vim.g.ai_cmp,
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            providers = {
                buffer = {
                    min_keyword_length = 8,
                    max_items = 5,
                },
            },
        },
        keymap = {
            -- default:
            preset = "enter",
            ["<C-y>"] = { "select_and_accept" },
            -- super tab:
            -- preset = "super-tab",
            -- ["<Right>"] = { "accept", "fallback" },
        },
    },
    opts_extend = { "sources.default" },
    -- Make blink.cmp toogleable
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
        return opts
    end,
}
