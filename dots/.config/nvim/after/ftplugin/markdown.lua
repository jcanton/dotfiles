-- gq/gw indent list continuations to the item's text via formatlistpat (fo+=n),
-- which these comments would take precedence over for bullets; autoindent
-- keeps that indent for the lines after (treesitter indent is off, see
-- plugins/treesitter.lua).
vim.opt_local.comments:remove({ "fb:*", "fb:-", "fb:+" })

-- render-markdown sets conceallevel back on every redraw, so LazyVim's
-- <leader>uc toggles rendering here (off shows the raw text, see
-- plugins/render-markdown.lua).
Snacks.toggle({
    name = "Conceal Level",
    get = function()
        return vim.wo.conceallevel > 0
    end,
    set = function(state)
        require("render-markdown").set_buf(state)
    end,
}):map("<leader>uc", { buffer = 0 })
