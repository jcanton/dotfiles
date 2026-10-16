-- The PR's files as a snacks sidebar picker (same look as <leader>e: tree,
-- search box), replacing codediff's own explorer in review tabs. Rows show
-- viewed, open threads, +/- lines and git status; opening a file shows it in
-- the diff and moves the cursor there (first change).
local M = {}

local render = require("pr_review.render")

local function lifecycle()
    return require("codediff.ui.lifecycle")
end

-- Tree items from codediff's (hidden) explorer file list: a root, then
-- directories (single-child chains merged, like GitHub) and files.
local function items(review, searching)
    local explorer = lifecycle().get_panel_view(review.tab)
    if not (explorer and explorer.tree) then
        return {}
    end
    local title = review.pr and ("#%d %s"):format(review.number, review.pr.title) or ("#" .. review.number)
    local root = { text = "", file = review.root, dir = true, open = true, root = true, name = title, children = {} }
    local dirs = { [""] = root }
    local function dir_for(rel)
        if dirs[rel] then
            return dirs[rel]
        end
        local parent_rel, name = rel:match("^(.*)/([^/]+)$")
        local parent = dir_for(parent_rel or "")
        local d = { dir = true, rel = rel, name = name or rel, parent = parent, children = {} }
        table.insert(parent.children, d)
        dirs[rel] = d
        return d
    end
    for _, f in ipairs(require("codediff.ui.explorer").get_all_files(explorer.tree)) do
        local rel = f.data.path
        local parent = dir_for(rel:match("^(.*)/[^/]+$") or "")
        table.insert(parent.children, { rel = rel, name = rel:match("[^/]+$"), parent = parent, cd = f.data })
    end
    local function compact(d)
        while not d.root and #d.children == 1 and d.children[1].dir do
            local c = d.children[1]
            d.name, d.rel, d.children = d.name .. "/" .. c.name, c.rel, c.children
            for _, cc in ipairs(d.children) do
                cc.parent = d
            end
        end
        for _, c in ipairs(d.children) do
            if c.dir then
                compact(c)
            end
        end
    end
    compact(root)
    local ret = { root }
    local function walk(d)
        table.sort(d.children, function(a, b)
            if a.dir ~= b.dir then
                return a.dir == true
            end
            return a.name < b.name
        end)
        for i, c in ipairs(d.children) do
            c.last = i == #d.children
            c.sort = (d.sort or "") .. ("%04d"):format(i)
            c.text = c.rel
            c.file = review.root .. "/" .. c.rel
            ret[#ret + 1] = c
            if c.dir then
                c.open = searching or not review.closed_dirs[c.rel]
                if c.open then
                    walk(c)
                end
            end
        end
    end
    root.sort = ""
    walk(root)
    return ret
end

---@param review pr_review.Review
function M.format(item, picker, review)
    local icons = picker.opts.icons.files
    local ret = {}
    if item.parent then
        vim.list_extend(ret, require("snacks.picker.format").tree(item, picker))
    end
    if item.dir then
        ret[#ret + 1] = { item.open and icons.dir_open or icons.dir, "SnacksPickerDirectory" }
        ret[#ret + 1] = { item.name, item.root and "SnacksPickerTitle" or "SnacksPickerDirectory" }
        return ret
    end
    local gh_file = review.files and review.files[item.rel]
    local icon, icon_hl = Snacks.util.icon(item.name, "file")
    ret[#ret + 1] = { icon .. " ", icon_hl }
    local name_hl = "SnacksPickerFile"
    if item.rel == review.shown then
        name_hl = "Special"
    elseif gh_file and gh_file.viewed then
        name_hl = "Comment"
    end
    ret[#ret + 1] = { item.name, name_hl }

    local right = {}
    local open = 0
    for _, t in ipairs(review.threads or {}) do
        if t.path == item.rel and not t.isResolved and not t.isOutdated then
            open = open + 1
        end
    end
    if open > 0 then
        right[#right + 1] = { render.signs.open[1] .. " " .. open .. " ", "PrReviewCount" }
    end
    if gh_file then
        if gh_file.additions > 0 then
            right[#right + 1] = { "+" .. gh_file.additions .. " ", "Added" }
        end
        if gh_file.deletions > 0 then
            right[#right + 1] = { "-" .. gh_file.deletions .. " ", "Removed" }
        end
    else
        right[#right + 1] = { "local ", "Comment" }
    end
    local status = (item.cd.status or "?"):sub(1, 1)
    right[#right + 1] = { status, ({ A = "Added", D = "Removed", R = "Changed" })[status] or "Changed" }
    right[#right + 1] = { gh_file and gh_file.viewed and " ✓" or "  ", "PrReviewViewed" }
    ret[#ret + 1] = { col = 0, virt_text = right, virt_text_pos = "right_align", hl_mode = "combine" }
    return ret
end

local function focus_diff(review)
    local session = lifecycle().get_session(review.tab)
    if not session then
        return
    end
    local win = session.single_side and session[session.single_side .. "_win"] or session.modified_win
    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
    end
end

-- Show `item` in the diff and put the cursor there; codediff lands on the
-- first change. The file loads asynchronously: init.sync() focuses again.
local function open_file(review, item)
    local session = lifecycle().get_session(review.tab)
    if session and render.shown_path(session) ~= item.rel then
        review.focus_diff = true
        lifecycle().get_panel_view(review.tab).on_file_select(item.cd)
    end
    focus_diff(review)
end

-- Called after a sync: focus the diff if a file was just opened, and keep
-- the picker in step with the shown file and the data.
function M.update(review, session, force)
    if review.focus_diff then
        review.focus_diff = nil
        focus_diff(review)
    end
    local picker = review.files_picker
    if not picker or picker.closed then
        return
    end
    local path = render.shown_path(session)
    local explorer = lifecycle().get_panel_view(review.tab)
    local count = explorer and explorer.tree and #require("codediff.ui.explorer").get_all_files(explorer.tree) or 0
    local key = path .. ":" .. count
    if not force and review.files_key == key then
        return
    end
    review.files_key, review.shown = key, path
    picker.list:set_target()
    picker:find({
        refresh = true,
        on_done = function()
            if picker.closed then
                return
            end
            for item, idx in picker:iter() do
                if item.rel == path then
                    picker.list:view(idx)
                    return
                end
            end
        end,
    })
end

function M.open(review)
    if review.files_picker and not review.files_picker.closed then
        return review.files_picker:focus()
    end
    review.closed_dirs = review.closed_dirs or {}
    review.files_key = nil
    review.files_picker = Snacks.picker({
        title = "PR files",
        -- typing a filter doesn't rerun the finder: force it when a search
        -- starts or ends, since searching shows collapsed directories too
        filter = {
            transform = function(_, filter)
                local searching = filter.pattern ~= "" or filter.search ~= ""
                if searching ~= review.files_searching then
                    review.files_searching = searching
                    return true
                end
            end,
        },
        finder = function()
            return items(review, review.files_searching)
        end,
        format = function(item, picker)
            return M.format(item, picker, review)
        end,
        layout = { preset = "sidebar", preview = false },
        focus = "list",
        auto_close = false,
        jump = { close = false },
        sort = { fields = { "sort" } },
        matcher = { sort_empty = false, fuzzy = false, keep_parents = true },
        confirm = function(picker, item)
            if not item or item.root then
                return
            end
            if item.dir then
                review.closed_dirs[item.rel] = not review.closed_dirs[item.rel] or nil
                return picker:find({ refresh = true })
            end
            open_file(review, item)
        end,
        actions = {
            pr_close_dir = {
                desc = "Close directory",
                action = function(picker, item)
                    local dir = item and (item.dir and item or item.parent)
                    if dir and not dir.root then
                        review.closed_dirs[dir.rel] = true
                        picker:find({ refresh = true })
                    end
                end,
            },
            pr_viewed = {
                desc = "Toggle viewed",
                action = function(_, item)
                    local ctx = require("pr_review.actions").context()
                    if ctx and item and not item.dir then
                        require("pr_review.actions").viewed(ctx, item.rel)
                    end
                end,
            },
            pr_hide = {
                desc = "Hide the file tree",
                action = function(picker)
                    picker:close()
                end,
            },
            pr_refresh = {
                desc = "Refresh from GitHub",
                action = function()
                    review:load()
                end,
            },
        },
        win = {
            list = {
                keys = {
                    ["l"] = "confirm",
                    ["h"] = "pr_close_dir",
                    ["v"] = "pr_viewed",
                    ["R"] = "pr_refresh",
                    -- like <leader>e on snacks' explorer: toggles
                    ["<leader>e"] = "pr_hide",
                    ["<leader>b"] = "pr_hide",
                },
            },
        },
        on_close = function()
            review.files_picker = nil
        end,
    })
end

function M.toggle(review)
    if review.files_picker and not review.files_picker.closed then
        review.files_picker:close()
    else
        M.open(review)
    end
end

return M
