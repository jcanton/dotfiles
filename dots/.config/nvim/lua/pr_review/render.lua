-- Draws a PR's review threads into a codediff session: snacks-style comment
-- boxes as virtual lines under the commented line, gutter signs, blank
-- fillers on the other pane so side-by-side stays aligned, and the lines
-- compact mode must keep unfolded (see the foldexpr hook in init.lua).
local M = {}

M.ns = vim.api.nvim_create_namespace("pr_review")
-- undecorated marks that follow edits to the real file, so threads stay on
-- their line when you edit during a review
M.ns_anchor = vim.api.nvim_create_namespace("pr_review_anchor")

-- bufnr -> { {row = 0-based anchor, first = 0-based first line, thread = ..., ...}, ... }
M.marks = {}
-- bufnr -> set of 1-based lines compact mode keeps visible
M.keep = {}
-- bufnr -> thread id -> anchor extmark id
M.anchors = {}

local INDENT = 1 -- columns between the text area and a box

for name, link in pairs({
    PrReviewBorder = "FloatBorder",
    PrReviewTitle = "FloatTitle",
    PrReviewButton = "Special",
    PrReviewMuted = "Comment",
    PrReviewOutdated = "DiagnosticWarn",
    PrReviewResolved = "DiagnosticOk",
    PrReviewPending = "DiagnosticWarn",
    PrReviewSign = "DiagnosticInfo",
    PrReviewFiller = "CodeDiffFiller",
    PrReviewViewed = "DiagnosticOk",
    PrReviewCount = "DiagnosticInfo",
}) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
end

M.reactions = {
    THUMBS_UP = "👍",
    THUMBS_DOWN = "👎",
    LAUGH = "😄",
    HOORAY = "🎉",
    CONFUSED = "😕",
    HEART = "❤️",
    ROCKET = "🚀",
    EYES = "👀",
}

M.signs = {
    open = { "\u{f075}", "PrReviewSign" },
    resolved = { "\u{f058}", "PrReviewResolved" },
    pending = { "\u{f254}", "PrReviewPending" },
}

-- snacks' gh icons, so boxes match its PR view
local function icons()
    local ok, gh = pcall(require, "snacks.gh")
    return ok and gh.config().icons or { user = "", logo = "" }
end

local function strwidth(s)
    return vim.api.nvim_strwidth(s)
end

local function chunks_width(chunks)
    local w = 0
    for _, c in ipairs(chunks) do
        w = w + strwidth(c[1])
    end
    return w
end

-- snacks.picker.Highlight[] (badges) -> virt_text chunks
local function flat(hls)
    local ret = {}
    for _, h in ipairs(hls) do
        if type(h[1]) == "string" and h[1] ~= "" then
            ret[#ret + 1] = { h[1], h[2] }
        end
    end
    return ret
end

local function badge(text, hl)
    return flat(Snacks.picker.highlight.badge(text, hl))
end

-- Wrap a chunk line to `max` cells, breaking after a space when possible.
local function wrap(chunks, max)
    local cells = {} -- { char, hl }
    for _, c in ipairs(chunks) do
        for _, ch in ipairs(vim.fn.split(c[1], "\\zs")) do
            cells[#cells + 1] = { ch, c[2] }
        end
    end
    local lines, line, w, space = {}, {}, 0, nil
    for _, cell in ipairs(cells) do
        local cw = strwidth(cell[1])
        if w + cw > max and #line > 0 then
            local rest = {}
            if space and space < #line then
                rest = vim.list_slice(line, space + 1)
                line = vim.list_slice(line, 1, space)
            end
            lines[#lines + 1] = line
            line, w, space = rest, 0, nil
            for _, r in ipairs(rest) do
                w = w + strwidth(r[1])
            end
        end
        line[#line + 1] = cell
        w = w + cw
        if cell[1] == " " then
            space = #line
        end
    end
    lines[#lines + 1] = line
    -- merge cells back into chunks
    return vim.tbl_map(function(l)
        local ret = {}
        for _, cell in ipairs(l) do
            local last = ret[#ret]
            if last and last[2] == cell[2] then
                last[1] = last[1] .. cell[1]
            else
                ret[#ret + 1] = { cell[1], cell[2] }
            end
        end
        return ret
    end, lines)
end

-- Comment body as highlighted, wrapped chunk lines. ```suggestion blocks get
-- the file's syntax and a badge, like snacks.
local function body_lines(body, path, max)
    local md, ret = {}, {}
    local ft = vim.filetype.match({ filename = path }) or ""
    for _, line in ipairs(vim.split((body or ""):gsub("\r", ""), "\n", { plain = true })) do
        if line:match("^%s*```suggestion%s*$") then
            line = line:gsub("suggestion", ft)
            md[#md + 1] = "Suggested change"
        end
        md[#md + 1] = line
    end
    while #md > 0 and not md[#md]:find("%S") do
        md[#md] = nil
    end
    local hl = Snacks.picker.highlight.get_virtual_lines(table.concat(md, "\n"), { ft = "markdown" })
    for i, chunks in ipairs(hl) do
        if md[i] == "Suggested change" then
            ret[#ret + 1] = badge("Suggested change", "SnacksGhSuggestionBadge")
        else
            -- fences are noise in a box
            local text = md[i] or ""
            if text:match("^%s*```") then
                chunks = { { text, "PrReviewMuted" } }
            end
            vim.list_extend(ret, wrap(chunks, max))
        end
    end
    return ret
end

local function comment_header(c, review)
    local ic = icons()
    local login = c.author.login
    local bot = login == "github-actions" or login:find("copilot") or login:find("%[bot%]")
    local ret =
        badge(("%s %s"):format(bot and ic.logo or ic.user, login), bot and "SnacksGhBotBadge" or "SnacksGhUserBadge")
    ret[#ret + 1] = { Snacks.picker.util.reltime(c.created), "SnacksPickerGitDate" }
    local assoc = c.authorAssociation
    assoc = assoc and assoc ~= "NONE" and Snacks.picker.util.title(assoc:lower()) or nil
    assoc = review.pr.author and login == review.pr.author.login and "Author" or assoc
    if assoc then
        ret[#ret + 1] = { " " }
        vim.list_extend(
            ret,
            badge(
                assoc,
                assoc == "Author" and "SnacksGhAuthorBadge"
                    or assoc == "Owner" and "SnacksGhOwnerBadge"
                    or "SnacksGhAssocBadge"
            )
        )
    end
    if c.state == "PENDING" then
        ret[#ret + 1] = { " " }
        vim.list_extend(ret, badge("Pending", "PrReviewPending"))
    end
    for _, r in ipairs(c.reactions) do
        ret[#ret + 1] = { " " }
        local text = ("%s %d"):format(M.reactions[r.content] or r.content, r.count)
        vim.list_extend(ret, badge(text, r.mine and "SnacksGhReviewApproved" or "SnacksGhReactionBadge"))
    end
    return ret
end

-- Buttons drawn in a box's bottom border; actions.click() maps clicks back.
local function buttons(thread)
    local ret = {}
    if thread.viewerCanReply then
        ret[#ret + 1] = { "reply", "↩ reply" }
    end
    ret[#ret + 1] = { "react", "☺ react" }
    if thread.isResolved and thread.viewerCanUnresolve then
        ret[#ret + 1] = { "resolve", "↺ unresolve" }
    elseif not thread.isResolved and thread.viewerCanResolve then
        ret[#ret + 1] = { "resolve", "✓ resolve" }
    end
    if vim.iter(thread.comments):any(function(c)
        return c.viewerCanUpdate
    end) then
        ret[#ret + 1] = { "edit", "✎ edit" }
    end
    ret[#ret + 1] = { "hide", "▴ hide" }
    return ret
end

local function thread_lines(thread)
    if thread.startLine and thread.startLine ~= thread.line then
        return ("%s%d–%d"):format(thread.diffSide:sub(1, 1), thread.startLine, thread.line)
    end
    local line = thread.isOutdated and thread.originalLine or thread.line
    return line and ("%s%d"):format(thread.diffSide:sub(1, 1), line) or "file"
end

---@return table virt_lines, table button_ranges {from, to, name} in box columns
function M.box(thread, idx, total, review, width)
    local collapsed = review:is_collapsed(thread)
    local inner = width - 4
    local title =
        { { (" %d/%d "):format(idx, total), "PrReviewTitle" }, { thread_lines(thread) .. " ", "PrReviewMuted" } }
    if thread.isOutdated then
        title[#title + 1] = { "Outdated ", "PrReviewOutdated" }
    end
    if thread.isResolved then
        local by = thread.resolvedBy and (" by " .. thread.resolvedBy.login) or ""
        title[#title + 1] = { "✓ Resolved" .. by .. " ", "PrReviewResolved" }
    end
    if thread.pending then
        title[#title + 1] = { "Pending ", "PrReviewPending" }
    end

    local lines = {}
    local function line(chunks)
        local pad = inner - chunks_width(chunks)
        local l = { { string.rep(" ", INDENT), "Normal" }, { "│ ", "PrReviewBorder" } }
        vim.list_extend(l, chunks)
        l[#l + 1] = { string.rep(" ", math.max(pad, 0)) .. " │", "PrReviewBorder" }
        lines[#lines + 1] = l
    end
    local function edge(left, right, label, fill_first)
        local w = chunks_width(label)
        local fill = string.rep("─", math.max(width - 3 - w, 0))
        local l =
            { { string.rep(" ", INDENT), "Normal" }, { left .. (fill_first and fill or "─"), "PrReviewBorder" } }
        vim.list_extend(l, label)
        l[#l + 1] = { (fill_first and "─" or fill) .. right, "PrReviewBorder" }
        lines[#lines + 1] = l
        return INDENT + strwidth(left) + strwidth(fill_first and fill or "─") -- column where the label starts
    end

    if collapsed then
        local first = thread.comments[1]
        local preview = first and (first.author.login .. ": " .. ((first.body or ""):match("[^\n]*") or "")) or ""
        local label = vim.deepcopy(title)
        label[#label + 1] = { preview, "PrReviewMuted" }
        local n = #thread.comments - 1
        if n > 0 then
            label[#label + 1] = { (" (+%d)"):format(n), "PrReviewMuted" }
        end
        -- keep room for the button
        local max = width - 16
        while chunks_width(label) > max and #label > 0 do
            local last = label[#label]
            local chars = vim.fn.split(last[1], "\\zs")
            if #chars <= 1 then
                table.remove(label)
            else
                last[1] = table.concat(chars, "", 1, #chars - 2) .. "…"
            end
        end
        label[#label + 1] = { " ", "PrReviewBorder" }
        local start = INDENT + 2 + chunks_width(label)
        label[#label + 1] = { "▾ show", "PrReviewButton" }
        label[#label + 1] = { " ", "PrReviewBorder" }
        local fill = string.rep("─", math.max(width - 3 - chunks_width(label), 0))
        local l = { { string.rep(" ", INDENT), "Normal" }, { "╶─", "PrReviewBorder" } }
        vim.list_extend(l, label)
        l[#l + 1] = { fill .. "╴", "PrReviewBorder" }
        lines[1] = l
        return lines, { { start, start + strwidth("▾ show"), "show" } }
    end

    edge("╭", "╮", title, false)
    for i, c in ipairs(thread.comments) do
        local guide = i > 1 and { { "┃ ", "PrReviewMuted" } } or {}
        local avail = inner - chunks_width(guide)
        if i > 1 then
            line({})
        end
        local header = vim.list_extend(vim.deepcopy(guide), comment_header(c, review))
        line(wrap(header, inner)[1])
        for _, chunks in ipairs(body_lines(c.body, thread.path, avail)) do
            line(vim.list_extend(vim.deepcopy(guide), chunks))
        end
    end
    -- footer buttons, right-aligned in the bottom border
    local label, ranges = {}, {}
    local col = 0
    for i, b in ipairs(buttons(thread)) do
        if i > 1 then
            label[#label + 1] = { "  ", "PrReviewBorder" }
            col = col + 2
        end
        ranges[#ranges + 1] = { col, col + strwidth(b[2]), b[1] }
        label[#label + 1] = { b[2], "PrReviewButton" }
        col = col + strwidth(b[2])
    end
    table.insert(label, 1, { " ", "PrReviewBorder" })
    label[#label + 1] = { " ", "PrReviewBorder" }
    local start = edge("╰", "╯", label, true) + 1
    for _, r in ipairs(ranges) do
        r[1], r[2] = r[1] + start, r[2] + start
    end
    return lines, ranges
end

-- Where a line of `from_side` lands on `to_side`: the same line in unchanged
-- regions, the end of the other side's block inside a change.
---@return integer row 0-based, boolean above
local function map_line(changes, from_side, to_side, lnum)
    local delta = 0
    for _, change in ipairs(changes) do
        local from, to = change[from_side], change[to_side]
        if lnum < from.start_line then
            break
        end
        if lnum < from.end_line then
            if to.end_line > to.start_line then
                return to.end_line - 2, false
            end
            local row = to.start_line - 2
            return math.max(row, 0), row < 0
        end
        delta = to.end_line - from.end_line
    end
    return lnum + delta - 1, false
end

-- In inline mode deleted lines are virt_lines above the change's first modified
-- line; a LEFT thread inside a change goes right below them.
local function inline_left(changes, lnum)
    for _, change in ipairs(changes) do
        local o, m = change.original, change.modified
        if lnum < o.start_line then
            break
        end
        if lnum < o.end_line then
            return m.start_line - 1, true
        end
    end
    return map_line(changes, "original", "modified", lnum)
end

local function clamp(buf, row)
    return math.max(0, math.min(row, vim.api.nvim_buf_line_count(buf) - 1))
end

-- Path of the file codediff shows in `session`.
function M.shown_path(session)
    return session.modified and session.modified.relative ~= "" and session.modified.relative
        or session.original and session.original.relative
end

local function text_width(win)
    local info = vim.fn.getwininfo(win)[1]
    return info and (info.width - info.textoff) or 80
end

function M.clear(buf, anchors)
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, M.ns, 0, -1)
        if anchors then
            vim.api.nvim_buf_clear_namespace(buf, M.ns_anchor, 0, -1)
        end
    end
    M.marks[buf], M.keep[buf] = nil, nil
    if anchors then
        M.anchors[buf] = nil
    end
end

-- 0-based row of a thread in a real buffer: where its anchor moved to, or
-- `row` (from GitHub) the first time.
local function anchored(buf, id, row)
    local ids = M.anchors[buf] or {}
    M.anchors[buf] = ids
    if ids[id] then
        local pos = vim.api.nvim_buf_get_extmark_by_id(buf, M.ns_anchor, ids[id], {})
        if pos[1] then
            return pos[1]
        end
    end
    ids[id] = vim.api.nvim_buf_set_extmark(buf, M.ns_anchor, row, 0, {})
    return row
end

-- Threads shown for `path`, in file order.
function M.threads_for(review, path)
    local ret = vim.tbl_filter(function(t)
        return t.path == path and (review.show_outdated or not t.isOutdated)
    end, review.threads or {})
    table.sort(ret, function(a, b)
        local la = (a.isOutdated and a.originalLine or a.line) or 0
        local lb = (b.isOutdated and b.originalLine or b.line) or 0
        if la ~= lb then
            return la < lb
        end
        return a.diffSide < b.diffSide
    end)
    return ret
end

--- Draw `review`'s threads for the file shown in codediff `session`.
---@return integer[] buffers drawn in
function M.draw(review, session)
    local path = M.shown_path(session)
    local changes = session.stored_diff_result and session.stored_diff_result.changes or {}
    local orig_buf, mod_buf = session.original_bufnr, session.modified_bufnr
    local orig_win, mod_win = session.original_win, session.modified_win
    local single = session.single_side
    local inline = session.layout == "inline"
    local real_mod = session.modified_revision == nil or session.modified_revision == "WORKING"
    local drawn = {}
    for _, buf in ipairs({ orig_buf, mod_buf }) do
        if buf and vim.api.nvim_buf_is_valid(buf) then
            M.clear(buf)
            M.marks[buf], M.keep[buf] = {}, {}
            drawn[#drawn + 1] = buf
        end
    end
    if not path or path == "" then
        return drawn
    end

    local threads = M.threads_for(review, path)
    for idx, thread in ipairs(threads) do
        local side = thread.diffSide == "LEFT" and "original" or "modified"
        local lnum = (thread.isOutdated and thread.originalLine or thread.line) or 1
        local first = thread.isOutdated and thread.originalStartLine or thread.startLine or lnum
        local file_level = thread.subjectType == "FILE"
        if
            side == "modified"
            and real_mod
            and not thread.isOutdated
            and not file_level
            and vim.api.nvim_buf_is_valid(mod_buf)
        then
            local row = anchored(mod_buf, thread.id, clamp(mod_buf, lnum - 1))
            first, lnum = row + 1 - (lnum - first), row + 1
        end
        local buf, win, row, above, other
        if inline or single then
            buf = single and session[single .. "_bufnr"] or mod_buf
            win = single and session[single .. "_win"] or mod_win
            if side == "original" and not single then
                row, above = inline_left(changes, lnum)
            elseif single and single ~= side then
                -- e.g. a LEFT thread on a file the PR adds: nothing to anchor to
                row, above = 0, true
            else
                row, above = lnum - 1, false
            end
        else
            buf = side == "original" and orig_buf or mod_buf
            win = side == "original" and orig_win or mod_win
            row, above = lnum - 1, false
            local other_side = side == "original" and "modified" or "original"
            other = {
                buf = other_side == "original" and orig_buf or mod_buf,
                pos = { map_line(changes, side, other_side, lnum) },
            }
        end
        if file_level then
            row, above = 0, true
        end
        if buf and vim.api.nvim_buf_is_valid(buf) and win and vim.api.nvim_win_is_valid(win) then
            row = clamp(buf, row)
            local width = math.min(review.config.box_width, text_width(win) - INDENT - 1)
            local virt, ranges = M.box(thread, idx, #threads, review, width)
            local sign = thread.pending and M.signs.pending or thread.isResolved and M.signs.resolved or M.signs.open
            vim.api.nvim_buf_set_extmark(buf, M.ns, row, 0, {
                virt_lines = virt,
                virt_lines_above = above,
                sign_text = sign[1],
                sign_hl_group = sign[2],
                -- virt_lines on one line draw by descending priority: below
                -- codediff's (100), so inline deleted lines come before the box
                priority = 50,
            })
            -- range of a multi-line comment
            local first_row = clamp(buf, first - 1)
            if not (inline and side == "original") and not file_level then
                for r = first_row, row - 1 do
                    vim.api.nvim_buf_set_extmark(
                        buf,
                        M.ns,
                        r,
                        0,
                        { sign_text = "┃", sign_hl_group = "PrReviewSign", priority = 200 }
                    )
                end
            end
            table.insert(M.marks[buf], {
                row = row,
                first = math.min(first_row, row),
                thread = thread,
                index = idx,
                total = #threads,
                height = #virt,
                buttons = ranges,
            })
            M.keep[buf][row + 1] = true
            if other and other.buf and vim.api.nvim_buf_is_valid(other.buf) then
                local orow, oabove = other.pos[1], other.pos[2]
                orow = clamp(other.buf, orow)
                local fill = {}
                for i = 1, #virt do
                    fill[i] = { { string.rep("╱", 500), "PrReviewFiller" } }
                end
                vim.api.nvim_buf_set_extmark(other.buf, M.ns, orow, 0, { virt_lines = fill, virt_lines_above = oabove })
                M.keep[other.buf][orow + 1] = true
            end
        end
    end
    return drawn
end

-- The thread marks of `buf` covering 0-based `row`.
function M.at(buf, row)
    return vim.tbl_filter(function(m)
        return row >= m.first and row <= m.row
    end, M.marks[buf] or {})
end

return M
