return {
    -- In-buffer markdown rendering: headings, bullets, code blocks, tables,
    -- callouts, checkboxes. Needs the markdown/markdown_inline treesitter
    -- parsers (auto_install in treesitter.lua handles those).
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
    },
    ft = { "markdown" },
    cmd = { "RenderMarkdown" },
    keys = {
        { "<leader>tm", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle markdown render" },
    },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
}
