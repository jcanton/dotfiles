-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

--  disable animations
vim.g.snacks_animate = false

-- disable relative line numbers
vim.opt.relativenumber = false

-- Try to fix annoying osc52 clipboard hang with ssh sessions
-- https://github.com/folke/which-key.nvim/issues/584
if vim.env.SSH_TTY then
    local function paste()
        return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
    end
    local osc52 = require("vim.ui.clipboard.osc52")
    vim.g.clipboard = {
        name = "OSC 52",
        copy = {
            ["+"] = osc52.copy("+"),
            ["*"] = osc52.copy("*"),
        },
        paste = {
            ["+"] = paste,
            ["*"] = paste,
        },
    }
end
