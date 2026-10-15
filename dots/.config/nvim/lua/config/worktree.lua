-- Switching git worktrees: used by <leader>gW (keymaps.lua) and when lazygit
-- quits after switching worktree (autocmds.lua).
local M = {}

-- cd to the worktree at root, reopen the current file in it and `git wt setup`
-- it (links + uv sync, no-op if already done).
function M.switch(root)
    local name = vim.api.nvim_buf_get_name(0)
    local old_root = name ~= "" and vim.fs.root(name, ".git")
    vim.cmd.cd(vim.fn.fnameescape(root))
    vim.cmd("clearjumps")
    local same_file = old_root and root .. name:sub(#old_root + 1)
    if same_file and vim.uv.fs_stat(same_file) then
        vim.cmd.edit(vim.fn.fnameescape(same_file))
    else
        vim.cmd.edit(".")
    end
    vim.notify("Switched to " .. root)
    vim.system({ "git", "wt", "setup", root }, { text = true }, function(obj)
        local done = vim.tbl_filter(function(line)
            return vim.startswith(line, "git wt:")
        end, vim.split(obj.stdout, "\n"))
        vim.schedule(function()
            if obj.code ~= 0 then
                vim.notify("git wt setup failed:\n" .. obj.stderr, vim.log.levels.ERROR)
            elseif #done > 0 then
                vim.notify(table.concat(done, "\n"))
            end
        end)
    end)
end

-- Fuzzy-pick a worktree of the current repo and switch to it.
function M.pick()
    local lines = vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })
    if vim.v.shell_error ~= 0 then
        vim.notify("Not in a git repository", vim.log.levels.WARN)
        return
    end
    -- porcelain: a "worktree <path>" line starts each entry, "branch refs/heads/<name>" follows
    local items = {}
    for _, line in ipairs(lines) do
        local path = line:match("^worktree (.+)$")
        local branch = line:match("^branch refs/heads/(.+)$")
        if path then
            items[#items + 1] = { path = path, branch = "(detached)" }
        elseif branch then
            items[#items].branch = branch
        end
    end
    for _, item in ipairs(items) do
        item.text = item.branch .. " " .. item.path
    end
    local current = vim.fs.root(vim.uv.cwd(), ".git")
    Snacks.picker({
        title = "Worktrees",
        items = items,
        layout = "select",
        format = function(item)
            return {
                { item.branch, "SnacksPickerGitBranch" },
                { "  " },
                { vim.fn.fnamemodify(item.path, ":~"), "Comment" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if item and item.path ~= current then
                M.switch(item.path)
            end
        end,
    })
end

return M
