return {
    "mason-org/mason.nvim",
    opts = {
        ensure_installed = {
            "fortls",
            "prettier", -- markdown formatter (lang.markdown extra); brew has it on mac
        },
    },
}
