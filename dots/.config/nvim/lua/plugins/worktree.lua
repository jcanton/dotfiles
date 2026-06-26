return {
  "ThePrimeagen/git-worktree.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    local Worktree = require("git-worktree")
    Worktree.setup({
      change_directory_command = "cd",
      update_on_change = true,
      update_on_change_command = "e .",
      clearjumps_on_change = true,
    })

    local function is_icon4py_repo(path)
      local result = vim.fn.system({ "git", "-C", path, "remote", "get-url", "origin" })
      return vim.trim(result) == "git@github.com:C2SM/icon4py.git"
    end

    local function link_repo_root(path, name, item)
      local target = path .. "/" .. item
      if vim.fn.getftype(target) == "link" then
        return
      end
      vim.notify("[worktree] link " .. item .. " for " .. name, vim.log.levels.INFO)
      vim.fn.system({ "ln", "-s", "../../" .. item, target })
    end

    local function link_worktree_assets(path, name)
      if not path:match("/%.worktrees/") then
        return
      end
      link_repo_root(path, name, "testdata")
      link_repo_root(path, name, "pyrightconfig.json")
    end

    local function run_uv_sync(path, name)
      if vim.fn.isdirectory(path .. "/.venv") == 1 then
        return
      end
      vim.notify("[worktree] uv sync: " .. name, vim.log.levels.INFO)
      vim.system({ "uv", "sync" }, { cwd = path }, function(obj)
        if obj.code == 0 then
          vim.notify("[worktree] uv sync done: " .. name, vim.log.levels.INFO)
        else
          vim.notify("[worktree] uv sync failed: " .. name, vim.log.levels.ERROR)
        end
      end)
    end

    Worktree.on_tree_change(function(op, metadata)
      if op ~= Worktree.Operations.Create and op ~= Worktree.Operations.Switch then
        return
      end
      local name = vim.fn.fnamemodify(metadata.path, ":t")
      if is_icon4py_repo(metadata.path) then
        link_worktree_assets(metadata.path, name)
        vim.schedule(function()
          run_uv_sync(metadata.path, name)
        end)
      end
    end)

    require("telescope").load_extension("git_worktree")

    vim.keymap.set("n", "<leader>gW", function()
      require("telescope").extensions.git_worktree.git_worktrees()
    end, { desc = "Worktrees" })
  end,
}
