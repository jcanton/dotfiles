-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

--------------------------------------------------------------------------------
--- Autoformat -----------------------------------------------------------------
--------------------------------------------------------------------------------

-- Autoformat setting
local set_autoformat = function(pattern, bool_val)
    vim.api.nvim_create_autocmd({ "FileType" }, {
        pattern = pattern,
        callback = function()
            vim.b.autoformat = bool_val
        end,
    })
end

set_autoformat({ "fortran" }, false)
set_autoformat({ "python" }, false)

--------------------------------------------------------------------------------
--- DAP ------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Create debugger configurations similarly to vscode launch.json
vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
        -- Track loaded projects with a global table
        if not vim.g._loaded_dap_projects then
            vim.g._loaded_dap_projects = {}
        end

        local cwd = vim.fn.getcwd()
        local project_dap = cwd .. "/.nvim/dap.lua"

        -- Load only if: file exists AND hasn't been loaded yet
        if vim.fn.filereadable(project_dap) == 1 and not vim.g._loaded_dap_projects[cwd] then
            dofile(project_dap)
            vim.g._loaded_dap_projects[cwd] = true -- Mark as loaded
        end
        -- Bonus: Manual Reload
        -- If you ever need to force-reload a project's config during the same session:
        -- :lua vim.g._loaded_dap_projects[vim.fn.getcwd()] = false
    end,
})
