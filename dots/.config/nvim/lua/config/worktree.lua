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

-- The worktrees of the repo at dir (default: cwd), nil outside one. Porcelain:
-- a "worktree <path>" line starts each entry, "branch refs/heads/<name>"
-- follows, and "prunable" (last) marks one whose directory is gone.
local function list(dir)
    local lines = vim.fn.systemlist({ "git", "-C", dir or ".", "worktree", "list", "--porcelain" })
    if vim.v.shell_error ~= 0 then
        return nil
    end
    local items = {}
    for _, line in ipairs(lines) do
        local path = line:match("^worktree (.+)$")
        local branch = line:match("^branch refs/heads/(.+)$")
        if path then
            items[#items + 1] = { path = path, branch = "(detached)" }
        elseif branch then
            items[#items].branch = branch
        elseif vim.startswith(line, "prunable") then
            items[#items] = nil
        end
    end
    return items
end

-- Switch to the worktree `git wt new` made for name (a fork's owner:branch is
-- checked out as branch).
local function switch_to(name, dir)
    local branch = name:gsub("^[^:]*:", "")
    for _, item in ipairs(list(dir) or {}) do
        if item.branch == branch then
            return M.switch(item.path)
        end
    end
    vim.notify("No worktree for " .. branch, vim.log.levels.WARN)
end

-- `git wt new` a worktree for a new or existing branch, in a terminal for its
-- questions, and switch to it.
function M.new()
    vim.ui.input({ prompt = "Branch name (new, existing or owner:branch): " }, function(name)
        if not name or name == "" then
            return
        end
        local term = Snacks.terminal.open({ "git", "wt", "new", name }, { auto_close = false })
        -- on failure the terminal stays open to show why
        term:on("TermClose", function()
            if vim.v.event.status == 0 then
                term:close()
                vim.schedule(function()
                    switch_to(name)
                end)
            end
        end, { buf = true })
    end)
end

-- lazygit's N (lazygit/config.yml) calls this through $NVIM once `git wt new`
-- made the worktree for name in the repo at dir: close lazygit, switch nvim to
-- the worktree and reopen lazygit in it.
function M.lazygit_created(dir, name)
    -- return to lazygit's remote call before killing it
    vim.schedule(function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local term = vim.b[buf].snacks_terminal
            if term and type(term.cmd) == "table" and term.cmd[1] == "lazygit" then
                vim.api.nvim_buf_delete(buf, { force = true })
            end
        end
        switch_to(name, dir)
        Snacks.lazygit()
    end)
end

-- Fuzzy-pick a worktree of the current repo and switch to it, or create one
-- with N (normal mode).
function M.pick()
    local items = list()
    if not items then
        vim.notify("Not in a git repository", vim.log.levels.WARN)
        return
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
