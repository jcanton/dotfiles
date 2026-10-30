return {
    "nvim-mini/mini.pairs",
    opts = {
        -- LazyVim also pairs in the cmdline, so / searches for "run(" got "run()"
        modes = { command = false },
        -- quotes don't pair after a letter or digit, so closing a word's quote
        -- (or typing an apostrophe) doesn't add another; brackets still do
        mappings = {
            ['"'] = { neigh_pattern = "^[^%w\\]" },
            ["'"] = { neigh_pattern = "^[^%w\\]" },
            ["`"] = { neigh_pattern = "^[^%w\\]" },
        },
    },
}
