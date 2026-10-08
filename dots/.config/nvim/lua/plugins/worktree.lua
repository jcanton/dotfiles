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

return {
    "polarmutex/git-worktree.nvim",
    version = "^2",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    init = function()
        -- read once when the plugin is first required
        vim.g.git_worktree = {
            change_directory_command = "cd",
            update_on_change_command = "e .",
            clearjumps_on_change = true,
        }
    end,
    config = function()
        local Hooks = require("git-worktree.hooks")

        -- Create always switches afterwards, so SWITCH covers new worktrees too.
        -- The hook's path can be relative to the previous cwd; the plugin has
        -- already cd'd into the worktree, so take the cwd instead.
        Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
            Hooks.builtins.update_current_buffer_on_switch(path, prev_path)
            local cwd = vim.uv.cwd()
            if is_icon4py_repo(cwd) then
                local name = vim.fn.fnamemodify(cwd, ":t")
                link_worktree_assets(cwd, name)
                run_uv_sync(cwd, name)
            end
        end)

        require("telescope").load_extension("git_worktree")
    end,
    keys = {
        {
            "<leader>gW",
            function()
                require("telescope").extensions.git_worktree.git_worktree()
            end,
            desc = "Worktrees",
        },
    },
}
