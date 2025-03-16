-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- DAP
vim.keymap.set("n", "<F5>", function()
    require("dap").continue()
end)
vim.keymap.set("n", "<F10>", function()
    require("dap").step_over()
end)
vim.keymap.set("n", "<F11>", function()
    require("dap").step_into()
end)
vim.keymap.set("n", "<F12>", function()
    require("dap").step_out()
end)

--------------------------------------------------------------------------------
--- The Primeagen --------------------------------------------------------------
--- https://www.youtube.com/watch?v=w7i4amO_zaE --------------------------------
--------------------------------------------------------------------------------

-- J joins lines but keeps the cursor where it is
vim.keymap.set("n", "J", "mzJ`z")

-- Use the void register for pasting with <leader>p
vim.keymap.set("x", "<leader>p", '"_dP')
