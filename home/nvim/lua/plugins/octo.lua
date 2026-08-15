return {
    "pwntester/octo.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
        "nvim-tree/nvim-web-devicons",
    },
    cmd = "Octo",
    keys = {
        { "<leader>op", "<cmd>Octo pr list<cr>", desc = "Octo: PR list" },
        { "<leader>oP", "<cmd>Octo pr search<cr>", desc = "Octo: PR search" },
        { "<leader>oi", "<cmd>Octo issue list<cr>", desc = "Octo: issue list" },
        { "<leader>oc", "<cmd>Octo pr checkout<cr>", desc = "Octo: checkout PR" },
        { "<leader>or", "<cmd>Octo review start<cr>", desc = "Octo: start review" },
        { "<leader>oR", "<cmd>Octo review resume<cr>", desc = "Octo: resume review" },
        { "<leader>oo", "<cmd>Octo actions<cr>", desc = "Octo: actions menu" },
    },
    opts = {
        picker = "telescope",
    },
}
