-- PlatformIO workflow (replaces the VS Code extension): clangd reads the compile_commands.json
-- that `pio run -t compiledb` writes, and <leader>i runs pio in a terminal split.

-- Kills any running pio terminal (e.g. a serial monitor holding the port) and wipes its buffer.
local function kill_pio()
    for _, term in ipairs(Snacks.terminal.list()) do
        if type(term.cmd) == "string" and term.cmd:match("^pio ") then
            vim.api.nvim_buf_delete(term.buf, { force = true })
        end
    end
end

-- Each run starts fresh: Snacks.terminal() would only toggle the previous window with the same cmd.
-- The cursor goes to the last line, so the window follows the output.
local function pio(args)
    return function()
        kill_pio()
        local term = Snacks.terminal.open("pio " .. args, { cwd = LazyVim.root(), win = { position = "bottom", height = 0.2 }, interactive = false })
        vim.api.nvim_win_call(term.win, function()
            vim.cmd("normal! G")
        end)
    end
end

return {
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            -- Let clangd ask arm-none-eabi-gcc for its system headers (stdlib.h, math.h, ...).
            local clangd = opts.servers.clangd
            clangd.cmd = vim.list_extend(vim.deepcopy(clangd.cmd or { "clangd" }), {
                "--query-driver=**/arm-none-eabi-*",
            })
            clangd.root_markers = vim.list_extend({ "platformio.ini" }, clangd.root_markers or {})
        end,
    },
    {
        "folke/which-key.nvim",
        opts = {
            spec = {
                -- nf-md-chip; written as a codepoint so the glyph survives editors without Nerd Font.
                { "<leader>i", group = "platformio", icon = { icon = vim.fn.nr2char(0xF061A), color = "orange" } },
            },
        },
    },
    {
        "folke/snacks.nvim",
        keys = {
            { "<leader>ib", pio("run"), desc = "Build" },
            { "<leader>iu", pio("run -t upload"), desc = "Upload" },
            { "<leader>im", pio("device monitor"), desc = "Serial monitor" },
            { "<leader>iU", pio("run -t upload && pio device monitor"), desc = "Upload + monitor" },
            { "<leader>ic", pio("run -t compiledb"), desc = "Refresh compile_commands.json" },
            { "<leader>ix", pio("run -t clean"), desc = "Clean" },
            { "<leader>ik", kill_pio, desc = "Kill pio terminal" },
        },
    },
}
