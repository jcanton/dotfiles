-- inc-rename's prompt is the command line `:IncRename <word>`; noice draws it
-- as a rename popup with `IncRename ` hidden, but only while the cursor is past
-- that prefix. Keep the cursor out of it: moving or deleting left of the word
-- would otherwise swap the popup for the plain cmdline (and <BS> would break
-- the command).
local function increname_prefix_end()
    if vim.fn.getcmdtype() ~= ":" then
        return nil
    end
    local inc_rename = package.loaded.inc_rename
    local cmd_name = inc_rename and inc_rename.config.cmd_name or "IncRename"
    local _, to = vim.fn.getcmdline():find("^%s*" .. cmd_name .. "%s+")
    return to
end

local function guard(key)
    return function()
        local to = increname_prefix_end()
        if not to then
            return key
        end
        local word_offset = vim.fn.getcmdpos() - 1 - to -- cursor bytes into the word
        if key == "<Home>" or key == "<C-b>" then
            return "<Home>" .. string.rep("<Right>", vim.fn.strchars(vim.fn.getcmdline():sub(1, to)))
        elseif key == "<C-u>" then
            return string.rep("<BS>", vim.fn.strchars(vim.fn.getcmdline():sub(to + 1, to + word_offset)))
        elseif word_offset <= 0 then
            return ""
        end
        return key
    end
end

-- An LSP rename edits the other files in hidden buffers and never writes them,
-- and auto-save only writes the buffer its event fired for: write every buffer
-- the rename touched.
local function write_renamed_buffers(result)
    local uris = vim.tbl_keys(result.changes or {})
    for _, change in ipairs(result.documentChanges or {}) do
        if change.textDocument then
            uris[#uris + 1] = change.textDocument.uri
        end
    end
    for _, uri in ipairs(uris) do
        local buf = vim.uri_to_bufnr(uri)
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modified then
            vim.api.nvim_buf_call(buf, function()
                vim.cmd("silent write")
            end)
        end
    end
end

return {
    "smjonas/inc-rename.nvim",
    init = function()
        for _, key in ipairs({ "<Left>", "<S-Left>", "<C-Left>", "<BS>", "<C-h>", "<C-w>", "<C-u>", "<Home>", "<C-b>" }) do
            vim.keymap.set("c", key, guard(key), { expr = true, desc = "Keep the cursor in the IncRename word" })
        end
    end,
    opts = {
        post_hook = write_renamed_buffers,
    },
}
