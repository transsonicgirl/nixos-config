return {
    "tpope/vim-fugitive",
    -- vim-rhubarb is the GitHub extension for fugitive: powers :GBrowse to
    -- github.com, permalinks, and #issue/@user completion in commit messages.
    -- (At work the Bitbucket equivalent was tommcdo/vim-fubitive.)
    dependencies = { "tpope/vim-rhubarb" },
    cmd = { "Git", "G", "GBrowse", "Gdiffsplit", "Gvdiffsplit", "Gread", "Gwrite", "Gedit" },
    keys = {
        { "<leader>gg", "<cmd>Git<cr>", desc = "Git status" },
        { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
        { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
        { "<leader>gl", "<cmd>Git log --oneline --graph --decorate<cr>", desc = "Git log" },
        { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
        { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git pull" },
        -- rhubarb: open current file/line on GitHub (works on a visual range too)
        { "<leader>gw", "<cmd>GBrowse<cr>", mode = { "n" }, desc = "Open on GitHub (GBrowse)" },
        { "<leader>gw", ":GBrowse<cr>", mode = { "x" }, desc = "Open selection on GitHub" },
        -- GBrowse! yanks the GitHub URL for the range to the unnamed register
        -- instead of opening it (for pasting a permalink into a PR review)
        { "<leader>gy", ":GBrowse!<cr>", mode = { "x" }, desc = "Yank GitHub link to selection" },
        { "<leader>gy", "<cmd>GBrowse!<cr>", mode = { "n" }, desc = "Yank GitHub link to line" },
    },
}
