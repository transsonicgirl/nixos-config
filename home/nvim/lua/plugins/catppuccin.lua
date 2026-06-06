return {
    {
        "catppuccin/nvim",
        config = function()
            require("catppuccin").setup({
                flavour = "mocha",
                integrations = {
                    alpha = true,
                },
                custom_highlights = function(colors)
                    return {
                        AlphaHeader = { fg = colors.mauve },
                    }
                end,
            })
            vim.cmd.colorscheme "catppuccin"
            vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = "#cba6f7", bg = "#313244", bold = true })
            vim.api.nvim_set_hl(0, 'CursorLine', { bg = "#313244" })
        end,
    },
}
