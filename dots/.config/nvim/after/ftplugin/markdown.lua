-- gq/gw indent list continuations to the item's text via formatlistpat (fo+=n),
-- which the runtime's fb:-/*/+ comments would take precedence over for bullets.
-- Lines after the second keep that indent through autoindent, so the
-- treesitter indentexpr is off for markdown (plugins/treesitter.lua).
vim.opt_local.comments:remove({ "fb:*", "fb:-", "fb:+" })
