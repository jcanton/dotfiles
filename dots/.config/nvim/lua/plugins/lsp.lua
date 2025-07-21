local util = require("lspconfig.util")

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ruff = {
        root_dir = function(fname)
          return util.find_git_ancestor(fname)
        end,
        init_options = {
          settings = {
            lint = {
              enable = false,
            },
          },
        },
      },
      pyright = {
        root_dir = function(fname)
          return util.find_git_ancestor(fname)
        end,
      },
    },
  },
}

