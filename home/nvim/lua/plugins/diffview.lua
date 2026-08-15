return {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = {
        "DiffviewOpen",
        "DiffviewClose",
        "DiffviewToggleFiles",
        "DiffviewFocusFiles",
        "DiffviewFileHistory",
    },
    keys = {
        { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
        { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
        { "<leader>gh", "<cmd>DiffviewFileHistory<cr>", desc = "Diffview repo history" },
        { "<leader>gH", "<cmd>DiffviewFileHistory %<cr>", desc = "Diffview file history" },
    },
    opts = {
        enhanced_diff_hl = true,
    },
}
