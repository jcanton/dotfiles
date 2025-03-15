return {
    "williamboman/mason.nvim",
    opts = {
        ensure_installed = {
            "pyright",
            "ruff",
            "mypy",
            "bash-language-server",
            "shfmt",
            "fortls",
        },
    },
}
