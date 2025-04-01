return {
    "okuuva/auto-save.nvim",
    lazy = false,
    opts = {
        trigger_events = { -- See :h events
            immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" }, -- vim events that trigger an immediate save
            defer_save = {}, -- vim events that trigger a deferred save (saves after `debounce_delay`)
            cancel_deferred_save = { "InsertEnter" }, -- vim events that cancel a pending deferred save
        },
        debounce_delay = 1000, -- delay after which a pending save is executed
    },
    keys = {
        { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
    },
}
