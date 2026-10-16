-- Everything bound to keys in a review tab: comment/reply/react/resolve/edit,
-- pending review start/submit/discard, viewed files, thread navigation, the
-- <CR> action menu, the ? key legend and clicks on the box buttons.
local M = {}

local gh = require("pr_review.gh")
local render = require("pr_review.render")

local function init()
    return require("pr_review")
end

local function notify(msg, level)
    init().notify(msg, level)
end

---@class pr_review.Ctx
---@field review pr_review.Review
---@field session table codediff session
---@field tab integer
---@field win integer
---@field buf integer
---@field side? "LEFT"|"RIGHT" diff side of the pane, nil outside the diff panes
---@field path string
---@field line integer cursor line (1-based)
---@field marks table[] thread marks at the cursor

---@return pr_review.Ctx?
function M.context()
    local tab = vim.api.nvim_get_current_tabpage()
    local review = init().reviews[tab]
    local session = review and review.threads and require("codediff.ui.lifecycle").get_session(tab)
    if not session then
        return
    end
    local win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_win_get_buf(win)
    local side
    if session.single_side then
        side = session.single_side == "original" and "LEFT" or "RIGHT"
    elseif buf == session.modified_bufnr then
        side = "RIGHT"
    elseif buf == session.original_bufnr then
        side = "LEFT"
    end
    local line = vim.api.nvim_win_get_cursor(win)[1]
    return {
        review = review,
        session = session,
        tab = tab,
        win = win,
        buf = buf,
        side = side,
        path = render.shown_path(session),
        line = line,
        marks = render.at(buf, line - 1),
    }
end

-- After a successful change: notify and refetch everything.
local function done(review, msg)
    return function(err)
        if err then
            return notify(err, vim.log.levels.ERROR)
        end
        if msg then
            notify(msg)
        end
        review:load()
    end
end

-- done(), but a failed post gives the composer text back as a draft
local function posted(review, restore, msg)
    return function(err)
        if err then
            restore()
        end
        done(review, msg)(err)
    end
end

local function confirm(prompt, yes, cb)
    vim.ui.select({ yes, "Cancel" }, { prompt = prompt }, function(choice)
        if choice == yes then
            cb()
        end
    end)
end

local function first_line(s)
    return ((s or ""):match("[^\n]*") or ""):sub(1, 60)
end

---@param cb fun(thread: table)
local function pick_thread(ctx, cb)
    local threads = vim.tbl_map(function(m)
        return m.thread
    end, ctx.marks)
    if #threads == 0 then
        return notify(
            "no review thread on this line (" .. init().config.keys.next_thread .. " jumps to the next)",
            vim.log.levels.WARN
        )
    elseif #threads == 1 then
        return cb(threads[1])
    end
    vim.ui.select(threads, {
        prompt = "Thread",
        format_item = function(t)
            return t.comments[1].author.login .. ": " .. first_line(t.comments[1].body)
        end,
    }, function(t)
        if t then
            cb(t)
        end
    end)
end

---@param filter? fun(c: table): boolean
---@param cb fun(comment: table, thread: table)
local function pick_comment(ctx, filter, cb, what)
    pick_thread(ctx, function(thread)
        local comments = vim.tbl_filter(filter or function()
            return true
        end, thread.comments)
        if #comments == 0 then
            return notify("no comment you can " .. what .. " in this thread", vim.log.levels.WARN)
        elseif #comments == 1 then
            return cb(comments[1], thread)
        end
        vim.ui.select(comments, {
            prompt = "Comment to " .. what,
            format_item = function(c)
                return c.author.login .. ": " .. first_line(c.body)
            end,
        }, function(c)
            if c then
                cb(c, thread)
            end
        end)
    end)
end

--------------------------------------------------------------------------------
-- Composer: a markdown float at the bottom of the diff pane
--------------------------------------------------------------------------------

local drafts = {} ---@type table<string, string>

---@class pr_review.compose.Action
---@field key string
---@field desc string
---@field fn fun(body: string, restore: fun())
---@field allow_empty? boolean

---@param opts {title: string, key: string, template?: string, actions: pr_review.compose.Action[], clean?: fun(body: string): string}
local function compose(opts)
    local parent = vim.api.nvim_get_current_win()
    local height = 12
    local keys = {}
    for i, a in ipairs(opts.actions) do
        keys["action" .. i] = {
            a.key,
            function(self)
                local body = self:text()
                if opts.clean then
                    body = opts.clean(body)
                end
                if not body:find("%S") and not a.allow_empty then
                    return notify("empty comment", vim.log.levels.WARN)
                end
                drafts[opts.key] = nil
                vim.cmd.stopinsert()
                self:close()
                a.fn(body, function()
                    drafts[opts.key] = body -- failed: keep it for the next try
                end)
            end,
            mode = { "n", "i" },
            desc = a.desc,
        }
    end
    -- replaces snacks' own `q = "close"`
    keys.q = {
        "q",
        function(self)
            drafts[opts.key] = self:text()
            self:close()
        end,
        desc = "Cancel (keeps draft)",
    }
    Snacks.win({
        relative = "win",
        win = parent,
        position = "float",
        width = 0,
        height = height,
        row = function(win)
            local border = win:border_size()
            return win:parent_size().height - height - border.top - border.bottom
        end,
        border = "top_bottom",
        backdrop = false,
        title = " " .. opts.title .. " ",
        footer_keys = true,
        ft = "markdown",
        text = drafts[opts.key] or opts.template or "",
        bo = { buftype = "nofile", bufhidden = "wipe", swapfile = false },
        wo = {
            wrap = true,
            linebreak = true,
            spell = true,
            winhighlight = "NormalFloat:Normal,FloatTitle:SnacksGhScratchTitle,FloatBorder:SnacksGhScratchBorder",
        },
        keys = keys,
        enter = true,
    })
    vim.cmd.startinsert()
end

-- The submit keys: into the pending review, or a single comment / new review.
---@param post fun(review_id?: string, cb: fun(err?: string))
local function submit_actions(review, post)
    local function to_review(body, restore)
        local function add(id)
            post(body, id, posted(review, restore))
        end
        if review.pending then
            return add(review.pending)
        end
        gh.mutate("add_review", { pullRequestId = review.pr.id, commitOID = review.pr.headRefOid }, function(err, res)
            if err then
                restore()
                return notify(err, vim.log.levels.ERROR)
            end
            review.pending = res.pullRequestReview.id
            add(review.pending)
        end)
    end
    if review.pending then
        return { { key = "<c-s>", desc = "Add review comment", fn = to_review } }
    end
    return {
        {
            key = "<c-s>",
            desc = "Comment",
            fn = function(body, restore)
                post(body, nil, posted(review, restore))
            end,
        },
        { key = "<c-r>", desc = "Start a review", fn = to_review },
    }
end

--------------------------------------------------------------------------------
-- Actions
--------------------------------------------------------------------------------

---@param ctx pr_review.Ctx
---@param range? {[1]: integer, [2]: integer} visual line range
function M.comment(ctx, range, file_level)
    if not ctx.side then
        return notify("comment from a diff pane", vim.log.levels.WARN)
    end
    local review = ctx.review
    local s, e = ctx.line, ctx.line
    if range then
        s, e = math.min(range[1], range[2]), math.max(range[1], range[2])
    end
    local side = ctx.side
    local where = file_level and "file"
        or s == e and ("%s%d"):format(side:sub(1, 1), e)
        or ("%s%d–%d"):format(side:sub(1, 1), s, e)
    local template, clean
    if range and side == "RIGHT" and not file_level then
        -- like snacks: start from a suggestion, dropped again if left unedited
        local code = vim.api.nvim_buf_get_lines(ctx.buf, s - 1, e, false)
        template = ("\n```suggestion\n%s\n```\n"):format(table.concat(code, "\n"))
        clean = function(body)
            local i, j = body:find(template, 1, true)
            return i and (body:sub(1, i - 1) .. body:sub(j + 1)) or body
        end
    end
    local path = ctx.path
    compose({
        title = ("Comment on %s · %s"):format(where, vim.fn.fnamemodify(path, ":t")),
        key = table.concat({ review.number, path, side, s, e, tostring(file_level) }, ":"),
        template = template,
        clean = clean,
        actions = submit_actions(review, function(body, review_id, cb)
            if review_id then
                gh.mutate("add_thread", {
                    pullRequestReviewId = review_id,
                    path = path,
                    body = body,
                    line = not file_level and e or nil,
                    side = not file_level and side or nil,
                    startLine = not file_level and s ~= e and s or nil,
                    startSide = not file_level and s ~= e and side or nil,
                    subjectType = file_level and "FILE" or "LINE",
                }, cb)
            else
                gh.single_comment(review.repo, review.number, {
                    body = body,
                    commit_id = review.pr.headRefOid,
                    path = path,
                    line = not file_level and e or nil,
                    side = not file_level and side or nil,
                    start_line = not file_level and s ~= e and s or nil,
                    start_side = not file_level and s ~= e and side or nil,
                    subject_type = file_level and "file" or "line",
                }, cb)
            end
        end),
    })
end

function M.file_comment(ctx)
    M.comment(ctx, nil, true)
end

function M.reply(ctx)
    local review = ctx.review
    pick_thread(ctx, function(thread)
        if not thread.viewerCanReply then
            return notify("you can't reply to this thread", vim.log.levels.WARN)
        end
        local first = thread.comments[1]
        compose({
            title = ("Reply to %s · %s"):format(first.author.login, first_line(first.body)),
            key = "reply:" .. thread.id,
            actions = submit_actions(review, function(body, review_id, cb)
                if review_id then
                    gh.mutate(
                        "add_reply",
                        { pullRequestReviewId = review_id, pullRequestReviewThreadId = thread.id, body = body },
                        cb
                    )
                else
                    gh.single_reply(review.repo, review.number, first.databaseId, body, cb)
                end
            end),
        })
    end)
end

function M.react(ctx)
    pick_comment(ctx, function(c)
        return c.viewerCanReact
    end, function(comment)
        local mine = {}
        for _, r in ipairs(comment.reactions) do
            mine[r.content] = r.mine
        end
        local order = { "THUMBS_UP", "THUMBS_DOWN", "LAUGH", "HOORAY", "CONFUSED", "HEART", "ROCKET", "EYES" }
        vim.ui.select(order, {
            prompt = "React to " .. comment.author.login,
            format_item = function(r)
                return ("%s %s%s"):format(
                    render.reactions[r],
                    r:lower():gsub("_", " "),
                    mine[r] and "  ✓ (remove)" or ""
                )
            end,
        }, function(r)
            if r then
                gh.mutate(
                    mine[r] and "remove_reaction" or "add_reaction",
                    { subjectId = comment.id, content = r },
                    done(ctx.review)
                )
            end
        end)
    end, "react to")
end

function M.resolve(ctx)
    pick_thread(ctx, function(thread)
        local undo = thread.isResolved
        if (undo and not thread.viewerCanUnresolve) or (not undo and not thread.viewerCanResolve) then
            return notify("you can't " .. (undo and "unresolve" or "resolve") .. " this thread", vim.log.levels.WARN)
        end
        gh.mutate(
            undo and "unresolve" or "resolve",
            { threadId = thread.id },
            done(ctx.review, undo and "unresolved" or "resolved")
        )
    end)
end

function M.edit(ctx)
    pick_comment(ctx, function(c)
        return c.viewerCanUpdate
    end, function(comment)
        compose({
            title = "Edit comment · " .. comment.author.login,
            key = "edit:" .. comment.id,
            template = comment.body,
            actions = {
                {
                    key = "<c-s>",
                    desc = "Save",
                    fn = function(body, restore)
                        gh.mutate(
                            "edit_comment",
                            { pullRequestReviewCommentId = comment.id, body = body },
                            posted(ctx.review, restore)
                        )
                    end,
                },
            },
        })
    end, "edit")
end

function M.delete(ctx)
    pick_comment(ctx, function(c)
        return c.viewerCanDelete
    end, function(comment)
        confirm("Delete comment: " .. first_line(comment.body), "Delete", function()
            gh.mutate("delete_comment", { id = comment.id }, done(ctx.review, "deleted"))
        end)
    end, "delete")
end

function M.toggle(ctx)
    pick_thread(ctx, function(thread)
        ctx.review.toggled[thread.id] = not ctx.review:is_collapsed(thread)
        init().sync(ctx.tab)
    end)
end

function M.outdated(ctx)
    ctx.review.show_outdated = not ctx.review.show_outdated
    notify((ctx.review.show_outdated and "showing" or "hiding") .. " outdated threads")
    init().redraw(ctx.tab)
end

-- explorer files in display order, and the explorer
local function explorer_files(tab)
    local explorer = require("codediff.ui.lifecycle").get_panel_view(tab)
    if not (explorer and explorer.tree) then
        return {}, nil
    end
    return require("codediff.ui.explorer").get_all_files(explorer.tree), explorer
end

---@param pred fun(path: string): boolean
local function select_file(ctx, dir, pred, what)
    local files, explorer = explorer_files(ctx.tab)
    local cur
    for i, f in ipairs(files) do
        if f.data.path == ctx.path then
            cur = i
        end
    end
    cur = cur or 0
    for step = 1, #files do
        local f = files[((cur - 1 + dir * step) % #files) + 1]
        if f and f.data.path ~= ctx.path and pred(f.data.path) then
            if explorer.winid and vim.api.nvim_win_is_valid(explorer.winid) and f.node._line then
                pcall(vim.api.nvim_win_set_cursor, explorer.winid, { f.node._line, 0 })
            end
            explorer.on_file_select(f.data)
            return true
        end
    end
    notify("no other " .. what, vim.log.levels.WARN)
end

---@param path? string file to toggle, default: the shown one
function M.viewed(ctx, path)
    local review = ctx.review
    path = path or ctx.path
    local file = review.files[path]
    if not file then
        return notify(path .. " is not part of the PR", vim.log.levels.WARN)
    end
    local viewed = not file.viewed
    gh.mutate(viewed and "mark_viewed" or "unmark_viewed", { pullRequestId = review.pr.id, path = path }, function(err)
        if err then
            return notify(err, vim.log.levels.ERROR)
        end
        file.viewed = viewed
        init().redraw(ctx.tab)
        if viewed and init().config.advance_on_viewed and path == ctx.path then
            select_file(ctx, 1, function(p)
                return review.files[p] and not review.files[p].viewed
            end, "unviewed file")
        end
    end)
end

local function has_open_threads(review, path)
    for _, t in ipairs(review.threads) do
        if t.path == path and not t.isResolved and (review.show_outdated or not t.isOutdated) then
            return true
        end
    end
end

function M.file_thread(ctx, dir)
    if
        select_file(ctx, dir, function(p)
            return has_open_threads(ctx.review, p)
        end, "file with open threads")
    then
        ctx.review.jump_first = true
    end
end

-- Jump to the next/prev thread box in the current pane (wraps). `n` = index.
function M.goto_thread(n, dir)
    local ctx = M.context()
    if not ctx then
        return
    end
    local rows = {}
    for _, m in ipairs(render.marks[ctx.buf] or {}) do
        rows[#rows + 1] = m.row + 1
    end
    if #rows == 0 then
        local session = ctx.session
        local other = ctx.buf == session.modified_bufnr and session.original_win or session.modified_win
        local other_buf = other and vim.api.nvim_win_is_valid(other) and vim.api.nvim_win_get_buf(other)
        if other_buf and render.marks[other_buf] and #render.marks[other_buf] > 0 then
            vim.api.nvim_set_current_win(other)
            return M.goto_thread(n, dir)
        end
        if n == nil then
            notify("no threads in this file", vim.log.levels.WARN)
        end
        return
    end
    table.sort(rows)
    local target
    if n then
        target = rows[n]
    elseif dir > 0 then
        target = vim.iter(rows):find(function(r)
            return r > ctx.line
        end) or rows[1]
    else
        target = vim.iter(rows):rev():find(function(r)
            return r < ctx.line
        end) or rows[#rows]
    end
    vim.api.nvim_win_set_cursor(ctx.win, { target, 0 })
    vim.cmd("normal! zv")
    -- show the box under the line
    local m = render.at(ctx.buf, target - 1)[1]
    if m then
        local info = vim.fn.getwininfo(ctx.win)[1]
        if target + m.height > info.botline then
            vim.cmd("normal! zt")
        end
    end
end

function M.start(ctx)
    local review = ctx.review
    if review.pending then
        return notify("you already have a pending review: " .. init().config.keys.submit .. " submits it")
    end
    gh.mutate(
        "add_review",
        { pullRequestId = review.pr.id, commitOID = review.pr.headRefOid },
        done(review, "review started")
    )
end

function M.submit(ctx)
    local review = ctx.review
    local events = { "Comment", "Approve", "Request changes" }
    local map = { Comment = "COMMENT", Approve = "APPROVE", ["Request changes"] = "REQUEST_CHANGES" }
    vim.ui.select(
        events,
        { prompt = review.pending and "Submit review" or "Review (no pending comments)" },
        function(choice)
            if not choice then
                return
            end
            local event = map[choice]
            compose({
                title = ("%s · PR #%d"):format(choice, review.number),
                key = "submit:" .. review.number,
                actions = {
                    {
                        key = "<c-s>",
                        desc = "Submit: " .. choice,
                        allow_empty = event == "APPROVE" or review.pending ~= nil,
                        fn = function(body, restore)
                            local cb = posted(review, restore, "review submitted: " .. choice)
                            if review.pending then
                                gh.mutate("submit_review", {
                                    pullRequestReviewId = review.pending,
                                    event = event,
                                    body = body ~= "" and body or nil,
                                }, cb)
                            else
                                gh.mutate("add_review", {
                                    pullRequestId = review.pr.id,
                                    commitOID = review.pr.headRefOid,
                                    event = event,
                                    body = body ~= "" and body or nil,
                                }, cb)
                            end
                        end,
                    },
                },
            })
        end
    )
end

function M.discard(ctx)
    local review = ctx.review
    if not review.pending then
        return notify("no pending review", vim.log.levels.WARN)
    end
    confirm("Discard your pending review and all its comments?", "Discard", function()
        gh.mutate("delete_review", { pullRequestReviewId = review.pending }, done(review, "pending review discarded"))
    end)
end

function M.browse(ctx)
    local m = ctx.marks[1]
    vim.ui.open(m and m.thread.comments[1].url or (ctx.review.pr.url .. "/files"))
end

function M.overview(ctx)
    vim.cmd.tabnew(("gh://%s/pr/%d"):format(ctx.review.repo, ctx.review.number))
end

function M.files(ctx)
    require("pr_review.files").open(ctx.review)
end

function M.files_toggle(ctx)
    require("pr_review.files").toggle(ctx.review)
end

function M.refresh(ctx)
    ctx.review:load(function()
        notify("refreshed")
    end)
end

--------------------------------------------------------------------------------
-- Key legend (?) and the <CR> action menu share one list of entries
--------------------------------------------------------------------------------

---@return {[1]: string, [2]: {[1]: string, [2]: string, [3]?: fun(ctx: pr_review.Ctx)}[]}[]
local function entries(ctx)
    local k = init().config.keys
    local review = ctx.review
    local ret = {}
    if #ctx.marks > 0 then
        local thread = ctx.marks[1].thread
        local own = vim.iter(thread.comments):any(function(c)
            return c.viewerCanUpdate
        end)
        local t = {
            { k.reply, "Reply", M.reply },
            { k.react, "React", M.react },
            { k.resolve, thread.isResolved and "Unresolve" or "Resolve", M.resolve },
            { k.toggle, review:is_collapsed(thread) and "Expand" or "Collapse", M.toggle },
            { k.browse, "Open thread on GitHub", M.browse },
        }
        if own then
            table.insert(t, 4, { k.edit, "Edit comment", M.edit })
            table.insert(t, 5, { k.delete, "Delete comment", M.delete })
        end
        ret[#ret + 1] = { "Thread", t }
    end
    if ctx.side then
        ret[#ret + 1] = {
            "Comment",
            {
                { k.comment, "Comment on line (visual: lines + suggestion)", M.comment },
                { k.file_comment, "Comment on file", M.file_comment },
            },
        }
    end
    local r = {}
    if review.pending then
        r[#r + 1] = { k.submit, "Submit pending review", M.submit }
        r[#r + 1] = { k.discard, "Discard pending review", M.discard }
    else
        r[#r + 1] = { k.start, "Start a review", M.start }
        r[#r + 1] = { k.submit, "Approve / request changes / comment", M.submit }
    end
    local file = review.files[ctx.path]
    r[#r + 1] = { k.viewed, file and file.viewed and "Unmark file viewed" or "Mark file viewed", M.viewed }
    ret[#ret + 1] = { "Review", r }
    ret[#ret + 1] = {
        "Navigate",
        {
            { k.next_thread .. " " .. k.prev_thread, "Next / prev thread" },
            { k.next_file_thread .. " " .. k.prev_file_thread, "Next / prev file with open threads" },
            { "]c [c", "Next / prev hunk" },
            { "]f [f", "Next / prev file" },
        },
    }
    ret[#ret + 1] = {
        "View",
        {
            { "t", "Toggle inline / side-by-side" },
            { "gc", "Toggle folding of unchanged lines" },
            { k.outdated, (review.show_outdated and "Hide" or "Show") .. " outdated threads", M.outdated },
            { k.files, "File tree (search, viewed, threads)", M.files },
            { k.files_toggle, "Toggle file tree", M.files_toggle },
            { k.overview, "PR conversation (snacks)", M.overview },
            { k.browse, "Open on GitHub", M.browse },
            { k.refresh, "Refresh from GitHub", M.refresh },
            { "g?", "codediff keys" },
            { "qq", "Close review (q twice, or hold q)" },
        },
    }
    return ret
end

local legend_win ---@type snacks.win?

function M.legend(ctx)
    if legend_win and legend_win:valid() then
        legend_win:close()
        legend_win = nil
        return
    end
    local sections = entries(ctx)
    local lines, hls = {}, {}
    local keyw = 0
    for _, section in ipairs(sections) do
        for _, e in ipairs(section[2]) do
            keyw = math.max(keyw, vim.api.nvim_strwidth(e[1]))
        end
    end
    for _, section in ipairs(sections) do
        if #lines > 0 then
            lines[#lines + 1] = ""
        end
        lines[#lines + 1] = section[1]
        hls[#hls + 1] = { #lines - 1, 0, #section[1], "Title" }
        for _, e in ipairs(section[2]) do
            local key = e[1] .. string.rep(" ", keyw - vim.api.nvim_strwidth(e[1]))
            lines[#lines + 1] = ("  %s  %s"):format(key, e[2])
            hls[#hls + 1] = { #lines - 1, 2, 2 + #key, "Special" }
        end
    end
    local width = 0
    for _, l in ipairs(lines) do
        width = math.max(width, vim.api.nvim_strwidth(l))
    end
    legend_win = Snacks.win({
        position = "float",
        relative = "editor",
        row = 1,
        col = vim.o.columns - width - 6,
        width = width + 2,
        height = #lines,
        border = "rounded",
        title = " PR review keys ",
        footer = " ? or moving closes ",
        footer_pos = "center",
        text = lines,
        enter = false,
        backdrop = false,
        zindex = 60,
        bo = { modifiable = false },
        wo = { winhighlight = "NormalFloat:Normal" },
    })
    local ns = vim.api.nvim_create_namespace("pr_review_legend")
    for _, h in ipairs(hls) do
        vim.api.nvim_buf_set_extmark(legend_win.buf, ns, h[1], h[2], { end_col = h[3], hl_group = h[4] })
    end
    -- close when leaving the pane
    vim.api.nvim_create_autocmd({ "CursorMoved", "WinLeave", "BufLeave" }, {
        buffer = ctx.buf,
        once = true,
        callback = function()
            if legend_win and legend_win:valid() then
                legend_win:close()
            end
            legend_win = nil
        end,
    })
end

function M.menu(ctx)
    local items = {}
    for _, section in ipairs(entries(ctx)) do
        for _, e in ipairs(section[2]) do
            if e[3] then
                items[#items + 1] = { section = section[1], key = e[1], desc = e[2], fn = e[3] }
            end
        end
    end
    vim.ui.select(items, {
        prompt = "PR #" .. ctx.review.number,
        format_item = function(it)
            return ("%-8s %-45s %s"):format(it.section, it.desc, it.key)
        end,
    }, function(it)
        if it then
            it.fn(ctx)
        end
    end)
end

--------------------------------------------------------------------------------
-- Clicks on box buttons
--------------------------------------------------------------------------------

local BUTTONS = {
    reply = M.reply,
    react = M.react,
    resolve = M.resolve,
    edit = M.edit,
    hide = M.toggle,
    show = M.toggle,
}

-- Map a click to a box button. Boxes are virtual lines, so read the screen:
-- walk up from the clicked row to the box's top edge, whose "i/n" says which
-- thread it is, then compare the column with the button ranges.
function M.click()
    local pos = vim.fn.getmousepos()
    local win = pos.winid
    if not (win and win ~= 0 and vim.api.nvim_win_is_valid(win)) then
        return
    end
    local buf = vim.api.nvim_win_get_buf(win)
    if not (render.marks[buf] and #render.marks[buf] > 0) then
        return
    end
    local info = vim.fn.getwininfo(win)[1]
    local text_col = info.wincol + info.textoff -- screen column of text column 0
    local border_col = text_col + 1 -- INDENT in render.lua
    local row = pos.screenrow
    local top
    for r = row, info.winrow, -1 do
        local ch = vim.fn.screenstring(r, border_col)
        if ch == "╭" or ch == "╶" then
            top = r
            break
        elseif ch ~= "│" and ch ~= "╰" then
            return
        end
    end
    if not top then
        return
    end
    local head = {}
    for c = border_col, border_col + 16 do
        head[#head + 1] = vim.fn.screenstring(top, c)
    end
    local idx = tonumber(table.concat(head):match("(%d+)/%d+"))
    local mark = idx and vim.iter(render.marks[buf]):find(function(m)
        return m.index == idx
    end)
    if not mark then
        return
    end
    local ch = vim.fn.screenstring(row, border_col)
    if ch ~= "╰" and ch ~= "╶" then
        return
    end
    local col = pos.screencol - text_col
    for _, b in ipairs(mark.buttons or {}) do
        if col >= b[1] and col < b[2] then
            vim.api.nvim_set_current_win(win)
            vim.api.nvim_win_set_cursor(win, { mark.row + 1, 0 })
            local ctx = M.context()
            if ctx then
                ctx.marks = { mark }
                BUTTONS[b[3]](ctx)
            end
            return
        end
    end
end

--------------------------------------------------------------------------------
-- Keymaps
--------------------------------------------------------------------------------

local function map(review, buf, mode, lhs, fn, desc, fallback)
    vim.keymap.set(mode, lhs, function()
        local ctx = M.context()
        if not ctx then
            if fallback then
                vim.api.nvim_feedkeys(vim.keycode(lhs), "n", false)
            end
            return
        end
        fn(ctx)
    end, { buffer = buf, desc = "PR: " .. desc })
    review.mapped[buf] = review.mapped[buf] or {}
    table.insert(review.mapped[buf], { mode, lhs })
end

-- Buffer-local keys for a diff pane (once per buffer and review).
function M.attach(review, buf)
    if review.mapped[buf] then
        return
    end
    local k = init().config.keys
    review.mapped[buf] = {}
    map(review, buf, "n", k.menu, M.menu, "actions", true)
    map(review, buf, "n", k.legend, M.legend, "keys", true)
    map(review, buf, "n", k.next_thread, function()
        M.goto_thread(nil, 1)
    end, "next thread", true)
    map(review, buf, "n", k.prev_thread, function()
        M.goto_thread(nil, -1)
    end, "prev thread", true)
    map(review, buf, "n", k.next_file_thread, function(ctx)
        M.file_thread(ctx, 1)
    end, "next file with open threads")
    map(review, buf, "n", k.prev_file_thread, function(ctx)
        M.file_thread(ctx, -1)
    end, "prev file with open threads")
    map(review, buf, "n", k.comment, M.comment, "comment on line")
    map(review, buf, "x", k.comment, function(ctx)
        local s, e = vim.fn.line("v"), vim.fn.line(".")
        vim.cmd("normal! \27")
        M.comment(ctx, { s, e })
    end, "comment on lines")
    for _, name in ipairs({
        "file_comment",
        "reply",
        "react",
        "resolve",
        "edit",
        "delete",
        "toggle",
        "outdated",
        "viewed",
        "start",
        "submit",
        "discard",
        "browse",
        "overview",
        "refresh",
        "files",
        "files_toggle",
    }) do
        map(review, buf, "n", k[name], M[name], (name:gsub("_", " ")))
    end
    map(review, buf, "n", "<LeftRelease>", function()
        M.click()
    end, "click box button", true)
    -- codediff closes with qq: a lone q only says so (and records no macro)
    map(review, buf, "n", "q", function()
        vim.api.nvim_echo({ { "qq (or hold q) closes the review", "WarningMsg" } }, false, {})
    end, "qq closes the review", true)
end

return M
