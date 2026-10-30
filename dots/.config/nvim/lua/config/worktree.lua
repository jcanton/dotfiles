-- Switching git worktrees: used by <leader>gW and <leader>gN (keymaps.lua) and
-- when lazygit quits after switching worktree (autocmds.lua).
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

-- Whether `git wt new` would check out an existing branch (see M.new).
local function branch_exists(name)
    if name:find(":") then
        return true
    end
    vim.fn.system({ "git", "show-ref", "--verify", "--quiet", "refs/heads/" .. name })
    if vim.v.shell_error == 0 then
        return true
    end
    vim.fn.system({ "git", "ls-remote", "--exit-code", "--heads", "origin", name })
    return vim.v.shell_error == 0
end

-- Worktree path of a branch name, which may be a fork's owner:branch.
local function worktree_path(main_repo, name)
    return main_repo .. "/.worktrees/" .. name:gsub("^[^:]*:", "")
end

-- Create a worktree (`git wt new`) and switch to it. An existing branch, local
-- or on origin (or a fork's owner:branch), is checked out; a new one is made
-- off the checked-out branch, or, when that is not the default one, off main
-- if chosen.
function M.new()
    local current = vim.trim(vim.fn.system({ "git", "branch", "--show-current" }))
    if vim.v.shell_error ~= 0 then
        vim.notify("Not in a git repository", vim.log.levels.WARN)
        return
    end
    local default = vim.trim(vim.fn.system({ "git", "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" }))
    default = vim.v.shell_error == 0 and default:gsub("^origin/", "") or "main"
    local main_repo =
        vim.fs.dirname(vim.trim(vim.fn.system({ "git", "rev-parse", "--path-format=absolute", "--git-common-dir" })))
    -- the detached HEAD of this worktree, not of the main repo
    local current_rev = current ~= "" and current or vim.trim(vim.fn.system({ "git", "rev-parse", "HEAD" }))
    local current_label = current ~= "" and current or "detached HEAD"
    vim.ui.input({ prompt = "Branch name (new, existing or owner:branch): " }, function(name)
        if not name or name == "" then
            return
        end
        local base = current_rev
        local exists = branch_exists(name)
        if not exists and current ~= default then
            local question = ("Branch %s off?"):format(name)
            local choice = vim.fn.confirm(question, ("&Current (%s)\n&Main (%s)\n&Abort"):format(current_label, default), 3)
            if choice == 2 then
                base = default
            elseif choice ~= 1 then
                return
            end
        end
        vim.notify("Creating worktree " .. name .. (exists and "" or " off " .. base) .. "...")
        vim.system({ "git", "wt", "new", name, base }, { text = true }, function(obj)
            vim.schedule(function()
                if obj.code ~= 0 then
                    vim.notify("git wt new failed:\n" .. obj.stderr, vim.log.levels.ERROR)
                else
                    M.switch(worktree_path(main_repo, name))
                end
            end)
        end)
    end)
end

-- lazygit's N (lazygit/config.yml) calls this through $NVIM once `git wt new`
-- made the worktree for branch: close lazygit, switch nvim to the worktree and
-- reopen lazygit in it.
function M.lazygit_created(git_common_dir, branch)
    -- return to lazygit's remote call before killing it
    vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local term = vim.b[buf].snacks_terminal
            if term and type(term.cmd) == "table" and term.cmd[1] == "lazygit" then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
        M.switch(worktree_path(vim.fs.dirname(git_common_dir), branch))
        Snacks.lazygit()
    end)
end

-- Fuzzy-pick a worktree of the current repo and switch to it, or create one
-- with N (normal mode).
function M.pick()
    local lines = vim.fn.systemlist({ "git", "worktree", "list", "--porcelain" })
    if vim.v.shell_error ~= 0 then
        vim.notify("Not in a git repository", vim.log.levels.WARN)
        return
    end
    -- porcelain: a "worktree <path>" line starts each entry, "branch refs/heads/<name>"
    -- follows, and "prunable" marks one whose directory is gone
    local items = {}
    for _, line in ipairs(lines) do
        local path = line:match("^worktree (.+)$")
        local branch = line:match("^branch refs/heads/(.+)$")
        if path then
            items[#items + 1] = { path = path, branch = "(detached)" }
        elseif branch then
            items[#items].branch = branch
        elseif vim.startswith(line, "prunable") then
            items[#items].prunable = true
        end
    end
    items = vim.tbl_filter(function(item)
        return not item.prunable
    end, items)
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
        actions = {
            new_worktree = function(picker)
                picker:close()
                M.new()
            end,
        },
        win = {
            input = { keys = { ["N"] = { "new_worktree", mode = "n" } } },
            list = { keys = { ["N"] = "new_worktree" } },
        },
    })
end

return M
