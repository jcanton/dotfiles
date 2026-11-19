-- Review GitHub PRs in codediff.nvim, like GitHub's "Files changed" tab.
--
-- Open with <leader>gR (PR of the current branch), r or "Review in worktree"
-- (<CR> <CR>) in the snacks PR picker (<leader>gp), or :PrReview [number].
-- The PR branch gets a worktree (git wt), the review opens in its own tab
-- with a tab-local cwd, so closing it (qq) returns to where you were.
--
-- gh.lua talks to GitHub, render.lua draws the threads into codediff's panes,
-- files.lua is the file tree, actions.lua has everything bound to keys (?).
local M = {}

local gh = require("pr_review.gh")
local render = require("pr_review.render")

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO, { title = "PR review" })
end
M.notify = notify

M.config = {
    box_width = 100,
    show_outdated = false, -- GitHub hides outdated threads in the diff too
    advance_on_viewed = true, -- marking a file viewed opens the next unviewed one
    refetch_after = 120, -- seconds: entering a review tab refetches older data
    keys = {
        menu = "<CR>",
        legend = "?",
        next_thread = "]t",
        prev_thread = "[t",
        next_file_thread = "]T",
        prev_file_thread = "[T",
        comment = "<leader>rc",
        file_comment = "<leader>rC",
        reply = "<leader>rr",
        react = "<leader>rE",
        resolve = "<leader>rx",
        edit = "<leader>re",
        delete = "<leader>rd",
        toggle = "<leader>rz",
        outdated = "<leader>ro",
        viewed = "<leader>rv",
        start = "<leader>rs",
        submit = "<leader>rS",
        discard = "<leader>rD",
        browse = "<leader>rb",
        overview = "<leader>rp",
        refresh = "<leader>rR",
        group = "<leader>r", -- which-key group of the keys above
        -- replace codediff's explorer keys with the snacks file tree
        files = "<leader>e",
        files_toggle = "<leader>b",
    },
}

---@class pr_review.Review: pr_review.Data
---@field tab integer
---@field root string worktree root
---@field repo string owner/name
---@field number integer
---@field config table
---@field toggled table<string, boolean> thread id -> collapsed, overriding the default
---@field show_outdated boolean
---@field stale? string why the worktree may not match the PR head
---@field fetched? integer
---@field drawn table<integer, boolean> buffers with our marks
---@field mapped table<integer, string[][]> buffer -> {mode, lhs} we mapped
---@field keep_key table<integer, string> buffer -> keep set we last folded with
---@field muted table<integer, boolean> buffers whose diagnostics we turned off
local Review = {}
Review.__index = Review

function Review.new(repo, number, root)
    return setmetatable({
        repo = repo,
        number = number,
        root = root,
        config = M.config,
        toggled = {},
        show_outdated = M.config.show_outdated,
        drawn = {},
        mapped = {},
        keep_key = {},
        muted = {},
    }, Review)
end

-- Resolved threads start collapsed, like on GitHub.
function Review:is_collapsed(thread)
    local t = self.toggled[thread.id]
    if t ~= nil then
        return t
    end
    return thread.isResolved
end

---@param cb? fun()
function Review:load(cb)
    gh.load(self.repo, self.number, function(err, data)
        if err or not data then
            return M.notify("PR #" .. self.number .. ": " .. (err or "no data"), vim.log.levels.ERROR)
        end
        -- explicitly: a submitted review must clear `pending`
        self.viewer, self.pr, self.pending = data.viewer, data.pr, data.pending
        self.threads, self.files = data.threads, data.files
        self.fetched = os.time()
        M.redraw(self.tab)
        if cb then
            cb()
        end
    end)
end

---@type table<integer, pr_review.Review>
M.reviews = {}

function M.current()
    return M.reviews[vim.api.nvim_get_current_tabpage()]
end

local function lifecycle()
    return require("codediff.ui.lifecycle")
end

--------------------------------------------------------------------------------
-- Drawing
--------------------------------------------------------------------------------

local function keep_key(buf)
    local lines = vim.tbl_keys(render.keep[buf] or {})
    table.sort(lines)
    return table.concat(lines, ",")
end

-- Redraw the threads of the file codediff shows in `tab`.
function M.sync(tab)
    local review = M.reviews[tab]
    local session = review and review.threads and lifecycle().get_session(tab)
    if not session then
        return
    end
    -- file switches leave the previous real buffer behind: clear it too
    for buf in pairs(review.drawn) do
        render.clear(buf)
    end
    review.drawn = {}
    for _, buf in ipairs(render.draw(review, session)) do
        review.drawn[buf] = true
        require("pr_review.actions").attach(review, buf)
    end
    -- compact mode: refold when the lines we keep open changed
    if session.compact_mode then
        for _, side in ipairs({ "original", "modified" }) do
            local win, buf = session[side .. "_win"], session[side .. "_bufnr"]
            if win and buf and vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_buf(win) == buf then
                local key = keep_key(buf)
                if review.keep_key[buf] ~= key then
                    review.keep_key[buf] = key
                    vim.api.nvim_win_call(win, function()
                        vim.cmd("silent! normal! zx")
                    end)
                end
            end
        end
    end
    if review.jump_first then
        review.jump_first = nil
        require("pr_review.actions").goto_thread(1)
    end
    require("pr_review.files").update(review, session)
end

-- The file tree replaces codediff's explorer: open it in the review's tab as
-- soon as codediff has the file list; GitHub's data fills in the rows later.
local function open_files(review)
    if not review.files_opened and vim.api.nvim_get_current_tabpage() == review.tab then
        review.files_opened = true
        require("pr_review.files").open(review)
    end
end

-- Redraw threads and file rows (after new data).
function M.redraw(tab)
    M.sync(tab)
    local review = M.reviews[tab]
    local session = review and lifecycle().get_session(tab)
    if session then
        open_files(review)
        require("pr_review.files").update(review, session, true)
    end
    vim.cmd.redrawstatus()
end

local queued = {}
local function queue_sync(tab)
    if queued[tab] then
        return
    end
    queued[tab] = true
    vim.schedule(function()
        queued[tab] = nil
        if M.reviews[tab] then
            M.sync(tab)
        end
    end)
end

function M.close(tab)
    local review = M.reviews[tab]
    if not review then
        return
    end
    M.reviews[tab] = nil
    if review.files_picker and not review.files_picker.closed then
        pcall(review.files_picker.close, review.files_picker)
    end
    -- every buffer we drew in also got keymaps
    for buf, maps in pairs(review.mapped) do
        render.clear(buf, true)
        if vim.api.nvim_buf_is_valid(buf) then
            for _, m in ipairs(maps) do
                pcall(vim.keymap.del, m[1], m[2], { buffer = buf })
            end
        end
    end
    for buf in pairs(review.muted) do
        if vim.api.nvim_buf_is_valid(buf) then
            vim.diagnostic.enable(true, { bufnr = buf })
        end
    end
end

--------------------------------------------------------------------------------
-- codediff integration
--------------------------------------------------------------------------------

local hooked = false

-- Called from the codediff spec once codediff is loaded.
function M.hook_codediff()
    if hooked then
        return
    end
    hooked = true

    -- codediff calls refresh.ready(tabpage) when a view finished rendering
    -- (file switch, layout toggle, re-diff after an edit), and every diff goes
    -- through view.render.render_diff: redraw our threads after either.
    local refresh = require("codediff.ui.refresh")
    local ready = refresh.ready
    refresh.ready = function(tabpage, ...)
        local ret = ready(tabpage, ...)
        if M.reviews[tabpage] then
            queue_sync(tabpage)
        end
        return ret
    end
    local view_render = require("codediff.ui.view.render")
    local render_diff = view_render.render_diff
    view_render.render_diff = function(...)
        local ret = render_diff(...)
        for tab in pairs(M.reviews) do
            queue_sync(tab)
        end
        return ret
    end

    -- compact mode folds everything far from a hunk; keep commented lines open
    local compact = require("codediff.ui.view.compact")
    local foldexpr = compact.foldexpr_eval
    compact.foldexpr_eval = function()
        local keep = render.keep[vim.api.nvim_win_get_buf(0)]
        if keep and keep[vim.v.lnum] then
            return "0"
        end
        return foldexpr()
    end

    -- codediff widens a pure insertion or deletion (an empty range) to one
    -- line, so the side without lines shows a line too many below it and the
    -- folds after it start one line apart. Treat the empty range as the
    -- boundary it is, as esmuellert/codediff.nvim#512 does; drop this once
    -- that is released.
    compact.compute_visible_lines = function(changes, side, line_count, context_lines)
        local visible = {}
        for _, change in ipairs(changes) do
            local range = change[side]
            for l = math.max(1, range.start_line - context_lines), math.min(line_count, range.end_line - 1 + context_lines) do
                visible[l] = true
            end
        end
        return visible
    end

    -- codediff mirrors folds across the panes only for the z keys: a fold
    -- opened by a search, l, a mark, undo, a jump or a click in the fold column
    -- changes one side and the panes drift apart. Even the z keys miss on a
    -- fold's first line next to a deleted line: codediff keeps one more line
    -- of context open on one side, so that line maps to an unfolded line.

    -- Give the fold at `lnum` of diff pane `win` the same state (open or
    -- closed) in the other pane.
    local function mirror_fold(win, lnum)
        local session = lifecycle().get_session(vim.api.nvim_win_get_tabpage(win))
        if not (session and session.compact_mode and session.layout ~= "inline") then
            return
        end
        local side = win == session.original_win and "original" or win == session.modified_win and "modified"
        local changes = session.stored_diff_result and session.stored_diff_result.changes
        local other = side == "original" and "modified" or "original"
        local other_win = session[other .. "_win"]
        if not (side and changes and other_win and vim.api.nvim_win_is_valid(other_win)) then
            return
        end
        -- the fold's state and line range (compact folds are runs of level 1)
        local fold = vim.api.nvim_win_call(win, function()
            if vim.fn.foldlevel(lnum) == 0 then
                return
            end
            if vim.fn.foldclosed(lnum) ~= -1 then
                return { true, vim.fn.foldclosed(lnum), vim.fn.foldclosedend(lnum) }
            end
            local s, e, n = lnum, lnum, vim.fn.line("$")
            while s > 1 and vim.fn.foldlevel(s - 1) > 0 do
                s = s - 1
            end
            while e < n and vim.fn.foldlevel(e + 1) > 0 do
                e = e + 1
            end
            return { false, s, e }
        end)
        if not fold then
            return
        end
        local closed, first, last = unpack(fold)
        local function map(l)
            return compact.compute_corresponding_lnum(changes, side, other, l)
        end
        vim.api.nvim_win_call(other_win, function()
            local n = vim.fn.line("$")
            local target = math.max(1, math.min(map(lnum), n))
            -- the line may map just outside the matching fold: take any line
            -- of that fold
            if vim.fn.foldlevel(target) == 0 then
                target = nil
                for l = math.max(1, map(first)), math.min(map(last), n) do
                    if vim.fn.foldlevel(l) > 0 then
                        target = l
                        break
                    end
                end
            end
            if target and (vim.fn.foldclosed(target) ~= -1) ~= closed then
                vim.cmd(target .. (closed and "foldclose" or "foldopen"))
            end
        end)
    end

    -- codediff describes its fold keys as "codediff: synced fold zo": say what
    -- they do instead
    local fold_desc = {
        zo = "Open fold",
        zO = "Open folds recursively",
        zc = "Close fold",
        zC = "Close folds recursively",
        za = "Toggle fold",
        zA = "Toggle folds recursively",
        zv = "Open folds to show cursor line",
        zx = "Refold, showing cursor line",
        zX = "Refold",
        zM = "Close all folds",
        zR = "Open all folds",
    }
    local set_buf_keymap = lifecycle().set_buf_keymap
    lifecycle().set_buf_keymap = function(tabpage, buf, mode, lhs, rhs, opts, ...)
        if opts and fold_desc[lhs] and opts.desc == "codediff: synced fold " .. lhs then
            opts = vim.tbl_extend("force", opts, { desc = fold_desc[lhs] .. " (both panes)" })
        end
        return set_buf_keymap(tabpage, buf, mode, lhs, rhs, opts, ...)
    end

    local function mirror_cursor_fold()
        mirror_fold(vim.api.nvim_get_current_win(), vim.fn.line("."))
    end

    -- after every command (z keys included, for the line codediff misses),
    -- once it is done: which-key replays the keys it waited on later
    vim.api.nvim_create_autocmd("SafeState", {
        group = vim.api.nvim_create_augroup("pr_review_folds", { clear = true }),
        callback = mirror_cursor_fold,
    })

    -- a click in the fold column toggles the fold without moving the cursor
    -- (or in the other pane): mirror it right away, closing included
    local ok, statuscolumn = pcall(require, "snacks.statuscolumn")
    if ok then
        local click_fold = statuscolumn.click_fold
        statuscolumn.click_fold = function(...)
            local pos = vim.fn.getmousepos()
            local ret = click_fold(...)
            if vim.api.nvim_win_is_valid(pos.winid) and pos.line > 0 then
                mirror_fold(pos.winid, pos.line)
            end
            return ret
        end
    end

    -- ]f / [f move the cursor in codediff's explorer window, which the file
    -- tree replaces (hidden: winid nil, and nvim_win_is_valid(nil) throws)
    local explorer = require("codediff.ui.explorer")
    for _, name in ipairs({ "navigate_next", "navigate_prev" }) do
        local navigate = explorer[name]
        explorer[name] = function(view, ...)
            if not (view and view.winid == nil) then
                return navigate(view, ...)
            end
            view.winid = -1
            local ok, err = pcall(navigate, view, ...)
            view.winid = nil
            if not ok then
                error(err, 0)
            end
        end
    end

    -- codediff reclaims its explorer keys over ours on TabEnter and on pane
    -- buffer changes, so route its explorer actions to the file tree instead
    local panes = require("codediff.ui.view.actions.panes")
    for name, files_fn in pairs({ toggle_explorer = "toggle", focus_explorer = "open" }) do
        local original = panes[name]
        panes[name] = function(ctx, ...)
            local review = ctx and M.reviews[ctx.tabpage]
            if review then
                return require("pr_review.files")[files_fn](review)
            end
            return original(ctx, ...)
        end
    end

    local group = vim.api.nvim_create_augroup("pr_review", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "CodeDiffOpen",
        callback = function(ev)
            local pending = M.pending
            local tab = ev.data and ev.data.tabpage
            if not (pending and tab) or vim.uv.now() - pending.time > 60000 then
                return
            end
            M.pending = nil
            require("codediff.config").options.explorer.hidden = pending.explorer_hidden
            local review = pending.review
            review.tab = tab
            M.reviews[tab] = review
            if vim.api.nvim_get_current_tabpage() == tab then
                vim.cmd.tcd(vim.fn.fnameescape(review.root))
            end
            vim.schedule(function()
                if M.reviews[tab] == review then
                    open_files(review)
                end
            end)
            review:load(function()
                local open = #vim.tbl_filter(function(t)
                    return not t.isResolved and not t.isOutdated
                end, review.threads)
                notify(
                    ("#%d %s\n%d open threads · %s for keys"):format(
                        review.number,
                        review.pr.title,
                        open,
                        M.config.keys.legend
                    )
                )
            end)
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "CodeDiffClose",
        callback = function(ev)
            local tab = ev.data and ev.data.tabpage
            if tab and M.reviews[tab] then
                M.close(tab)
                -- holding q to close (qq) keeps sending q: don't let the
                -- rest start a macro recording in the tab we land in
                if vim.fn.maparg("q", "n") == "" then
                    vim.keymap.set("n", "q", "<Nop>")
                    vim.defer_fn(function()
                        pcall(vim.keymap.del, "n", "q")
                    end, 700)
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("TabClosed", {
        group = group,
        callback = function()
            for tab in pairs(M.reviews) do
                if not vim.api.nvim_tabpage_is_valid(tab) then
                    M.close(tab)
                end
            end
        end,
    })
    -- boxes are sized to their pane
    vim.api.nvim_create_autocmd("WinResized", {
        group = group,
        callback = function()
            for _, win in ipairs(vim.v.event.windows or {}) do
                local ok, tab = pcall(vim.api.nvim_win_get_tabpage, win)
                if ok and M.reviews[tab] then
                    queue_sync(tab)
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("TabEnter", {
        group = group,
        callback = function()
            local review = M.current()
            if review then
                open_files(review)
            end
            if review and review.fetched and os.time() - review.fetched > M.config.refetch_after then
                review:load()
            end
        end,
    })
end

function M.statusline()
    local review = M.current()
    if not (review and review.pr) then
        return ""
    end
    local parts = { ("#%d"):format(review.number) }
    local total, viewed = 0, 0
    for _, f in pairs(review.files) do
        total = total + 1
        viewed = viewed + (f.viewed and 1 or 0)
    end
    parts[#parts + 1] = ("✓ %d/%d viewed"):format(viewed, total)
    local open, mine = 0, 0
    for _, t in ipairs(review.threads) do
        open = open + ((not t.isResolved and not t.isOutdated) and 1 or 0)
        for _, c in ipairs(t.comments) do
            mine = mine + (c.state == "PENDING" and 1 or 0)
        end
    end
    parts[#parts + 1] = ("%s %d open"):format(render.signs.open[1], open)
    if review.pending then
        parts[#parts + 1] = ("%s review: %d pending"):format(render.signs.pending[1], mine)
    end
    local checks = vim.tbl_get(review.pr, "commits", "nodes", 1, "commit", "statusCheckRollup", "state")
    if checks then
        local icon = ({ SUCCESS = "✓", FAILURE = "✗", ERROR = "✗", PENDING = "●", EXPECTED = "●" })[checks]
            or "?"
        parts[#parts + 1] = ("CI %s %s"):format(icon, checks:lower())
    end
    if review.stale then
        parts[#parts + 1] = "⚠ " .. review.stale
    end
    return table.concat(parts, " · ")
end

--------------------------------------------------------------------------------
-- Opening a review
--------------------------------------------------------------------------------

---@param cb fun(ok: boolean, out: string)
local function git(args, cwd, cb)
    vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }, function(obj)
        vim.schedule(function()
            cb(obj.code == 0, vim.trim(obj.code == 0 and obj.stdout or obj.stderr))
        end)
    end)
end

local function git_sync(args, cwd)
    local obj = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
    return obj.code == 0 and vim.trim(obj.stdout) or nil
end

local function repo_of(url)
    if url then
        return url:match("github%.com[:/]([^/]+/[^/]-)%.git$") or url:match("github%.com[:/]([^/]+/[^/]+)$")
    end
end

-- Remote whose URL points at GitHub repo `repo` (owner/name).
local function remote_for(root, repo)
    for _, line in ipairs(vim.split(git_sync({ "remote", "-v" }, root) or "", "\n")) do
        local name, url = line:match("^(%S+)%s+(%S+)%s+%(fetch%)")
        if name and repo_of(url) and repo_of(url):lower() == repo:lower() then
            return name
        end
    end
end

-- Worktree of the main repo whose branch is the PR head. Fork heads are found
-- by upstream (fork-<owner>/<branch>), so local names like owner/branch work.
local function find_worktree(main, pr)
    local upstreams = {}
    local refs = git_sync({ "for-each-ref", "--format=%(refname:short) %(upstream:short)", "refs/heads" }, main)
    for _, line in ipairs(vim.split(refs or "", "\n")) do
        local branch, up = line:match("^(%S+)%s*(%S*)$")
        if branch then
            upstreams[branch] = up
        end
    end
    local head = pr.headRefName
    local want = pr.isCrossRepository and ("fork-%s/%s"):format(pr.headRepositoryOwner.login, head) or nil
    local path
    for _, line in ipairs(vim.split(git_sync({ "worktree", "list", "--porcelain" }, main) or "", "\n")) do
        path = line:match("^worktree (.+)$") or path
        local branch = line:match("^branch refs/heads/(.+)$")
        if branch then
            local up = upstreams[branch] or ""
            if want and up == want then
                return path
            end
            if not want and branch == head and (up == "" or up:match("/(.+)$") == head) then
                return path
            end
        end
    end
end

-- Find or create (git wt add) the PR head's worktree.
---@param cb fun(root?: string)
local function ensure_worktree(main, pr, cb)
    local root = find_worktree(main, pr)
    if root then
        return cb(root)
    end
    local spec = pr.isCrossRepository and (pr.headRepositoryOwner.login .. ":" .. pr.headRefName) or pr.headRefName
    notify("git wt add " .. spec .. " …")
    git({ "wt", "add", spec }, main, function(ok, out)
        if not ok then
            notify("git wt add " .. spec .. " failed:\n" .. out, vim.log.levels.ERROR)
            return cb()
        end
        cb(find_worktree(main, pr))
    end)
end

-- Make sure the worktree is at the PR head: offer a fast-forward when behind.
---@param cb fun(stale?: string)
local function sync_head(root, pr, cb)
    local head = git_sync({ "rev-parse", "HEAD" }, root)
    if head == pr.headRefOid then
        return cb()
    end
    local upstream = git_sync({ "rev-parse", "--abbrev-ref", "@{upstream}" }, root)
    local remote, branch = (upstream or ""):match("^([^/]+)/(.+)$")
    local function check()
        local behind = git_sync({ "rev-list", "--count", "HEAD.." .. pr.headRefOid }, root)
        if not behind then
            return cb("PR head not fetched")
        end
        -- git_sync gives "" on success: --is-ancestor only has an exit code
        if not git_sync({ "merge-base", "--is-ancestor", "HEAD", pr.headRefOid }, root) then
            return cb("local branch diverged from PR head")
        end
        if git_sync({ "status", "--porcelain", "--untracked-files=no" }, root) ~= "" then
            return cb(behind .. " commits behind PR head (local changes)")
        end
        vim.ui.select({ "Fast-forward to the PR head", "Review the local state" }, {
            prompt = ("%s is %s commits behind PR #%d"):format(pr.headRefName, behind, pr.number),
        }, function(choice)
            if choice ~= "Fast-forward to the PR head" then
                return cb(behind .. " commits behind PR head")
            end
            git({ "merge", "--ff-only", pr.headRefOid }, root, function(ok, out)
                if not ok then
                    notify("fast-forward failed:\n" .. out, vim.log.levels.ERROR)
                    return cb("behind PR head")
                end
                cb()
            end)
        end)
    end
    if remote then
        git({ "fetch", remote, branch }, root, check)
    else
        check()
    end
end

---@param repo string owner/name
---@param number integer
local function open_pr(repo, number)
    for tab, review in pairs(M.reviews) do
        if review.repo == repo and review.number == number and vim.api.nvim_tabpage_is_valid(tab) then
            vim.api.nvim_set_current_tabpage(tab)
            return review:load()
        end
    end
    local main = git_sync({ "rev-parse", "--path-format=absolute", "--git-common-dir" })
    if not main then
        return notify("not in a git repository", vim.log.levels.ERROR)
    end
    main = vim.fs.dirname(main)
    notify(("Opening PR #%d …"):format(number))
    gh.pr(repo, number, function(err, _, pr)
        if err or not pr then
            return notify(err or "PR not found", vim.log.levels.ERROR)
        end
        ensure_worktree(main, pr, function(root)
            if not root then
                return
            end
            sync_head(root, pr, function(stale)
                local base_remote = remote_for(root, pr.baseRepository.nameWithOwner) or "origin"
                git({ "fetch", base_remote, pr.baseRefName }, root, function()
                    local review = Review.new(repo, number, root)
                    review.stale = stale
                    -- the snacks file tree (files.lua) replaces codediff's explorer
                    local explorer_opts = require("codediff.config").options.explorer
                    local pending = { review = review, time = vim.uv.now(), explorer_hidden = explorer_opts.hidden }
                    M.pending, explorer_opts.hidden = pending, true
                    vim.defer_fn(function()
                        if M.pending == pending then
                            M.pending, explorer_opts.hidden = nil, pending.explorer_hidden
                        end
                    end, 60000)
                    vim.cmd({
                        cmd = "CodeDiff",
                        args = { "-C", root, ("%s/%s..."):format(base_remote, pr.baseRefName) },
                    })
                end)
            end)
        end)
    end)
end

---@param opts? {repo?: string, number?: integer}
function M.open(opts)
    opts = opts or {}
    if opts.number then
        local repo = opts.repo or repo_of(git_sync({ "remote", "get-url", "origin" }) or "")
        if not repo then
            return notify("can't tell the GitHub repo: pass owner/name", vim.log.levels.ERROR)
        end
        return open_pr(repo, opts.number)
    end
    -- the current branch's PR: gh resolves fork upstreams itself
    gh.run({ "pr", "view", "--json", "number,url" }, nil, function(err, out)
        local ok, data = pcall(vim.json.decode, out or "")
        if err or not ok or type(data) ~= "table" then
            return notify("no PR for the current branch" .. (err and (":\n" .. err) or ""), vim.log.levels.WARN)
        end
        open_pr(data.url:match("github%.com/([^/]+/[^/]+)/pull/"), data.number)
    end)
end

--------------------------------------------------------------------------------
-- Setup (VeryLazy): command and the snacks PR action menu entry
--------------------------------------------------------------------------------

function M.setup()
    vim.api.nvim_create_user_command("PrReview", function(cmd)
        local arg = cmd.args
        local repo, number = arg:match("github%.com/([^/]+/[^/]+)/pull/(%d+)")
        number = number or arg:match("^#?(%d+)$")
        if arg ~= "" and not number then
            return notify("usage: :PrReview [number|url]", vim.log.levels.ERROR)
        end
        M.open({ repo = repo, number = tonumber(number) })
    end, { nargs = "?", desc = "Review a GitHub PR in codediff" })

    -- entry in the snacks gh <CR> action menu (PR list, PR buffers)
    local ok, actions = pcall(require, "snacks.gh.actions")
    if ok then
        actions.actions.gh_review_worktree = {
            desc = "Review in worktree",
            title = "Review PR #{number} in worktree",
            icon = render.signs.open[1] .. " ",
            priority = 300, -- first in the menu
            type = "pr",
            action = function(item, ctx)
                if ctx.picker then
                    ctx.picker:close()
                end
                M.open({ repo = item.repo, number = item.number })
            end,
        }
    end
end

return M
