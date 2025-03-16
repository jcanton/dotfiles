return {
    "neovim/nvim-lspconfig",
    opts = {
        servers = {
            ruff = {
                init_options = {
                    settings = {
                        lint = {
                            enable = false,
                        },
                    },
                },
            },
            pyright = {
                before_init = function(_, config)
                    -- look for local venv and use that if found
                    local venv_path = vim.fn.getcwd() .. "/.venv/bin/python"
                    if vim.fn.filereadable(venv_path) == 1 then
                        config.settings.python.pythonPath = venv_path
                    else
                        config.settings.python.pythonPath = vim.fn.exepath("python") -- fallback to system python
                    end
                end,
            },
        },
    },
}
