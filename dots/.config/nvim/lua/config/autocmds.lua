-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

--------------------------------------------------------------------------------
--- Conceal level --------------------------------------------------------------
--------------------------------------------------------------------------------

-- The default conceallevel is 3
vim.api.nvim_create_autocmd("FileType", {
    pattern = { "tex" },
    callback = function()
        vim.opt.conceallevel = 0
    end,
})

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
--- LSP highlight fix for fortls -----------------------------------------------
--------------------------------------------------------------------------------

-- fortls handles textDocument/documentHighlight but doesn't advertise the
-- capability, so Snacks.words checks supports_method() and skips it.
--
-- It also answers documentHighlight with its *references* handler, which returns
-- project-wide Location[] objects ({uri, range}) instead of the bare
-- DocumentHighlight[] ({range, kind}) the protocol expects. Neovim's default
-- handler assumes every range belongs to the current buffer, so matches from
-- *other* files get painted onto this buffer at the same line/column -> stray
-- characters and whitespace light up. Filter results down to the requested
-- document before the stock handler renders them.
vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp_fortls_highlight", { clear = true }),
    desc = "Enable + fix document highlight for fortls",
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not (client and client.name == "fortls") then
            return
        end

        client.server_capabilities.documentHighlightProvider = true

        local default = vim.lsp.handlers["textDocument/documentHighlight"]
        client.handlers["textDocument/documentHighlight"] = function(err, result, ctx, config)
            if result and ctx.params and ctx.params.textDocument then
                local want = vim.uri_to_fname(ctx.params.textDocument.uri)
                result = vim.tbl_filter(function(item)
                    -- keep bare DocumentHighlight (no uri) + current-file matches
                    return item.uri == nil or vim.uri_to_fname(item.uri) == want
                end, result)
            end
            return default(err, result, ctx, config)
        end
    end,
})

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
