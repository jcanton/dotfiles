return {
    "nvim-mini/mini.pairs",
    opts = {
        -- LazyVim also pairs in the cmdline, so / searches for "run(" got "run()"
        modes = { command = false },
        -- quotes pair only after whitespace, the line start or an opening
        -- bracket: closing one after a word or symbol (refine_*`, an
        -- apostrophe) doesn't add another. Brackets still pair anywhere.
        mappings = {
            ['"'] = { neigh_pattern = "^[%s%(%[{]" },
            ["'"] = { neigh_pattern = "^[%s%(%[{]" },
            ["`"] = { neigh_pattern = "^[%s%(%[{]" },
        },
    },
}
