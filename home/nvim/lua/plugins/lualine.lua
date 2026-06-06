return {
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        dependencies = { "nvim-tree/nvim-web-devicons", "archibate/lualine-time" },
        config = function()
            require("lualine").setup({
                options = {
                    icons_enabled = true,
                    theme = "iceberg_dark",
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                    disabled_filetypes = {
                        statusline = {},
                        winbar = {},
                    },
                    ignore_focus = {},
                    always_divide_middle = true,
                    always_show_tabline = true,
                    globalstatus = false,
                    refresh = {
                        statusline = 100,
                        tabline = 100,
                        winbar = 100,
                    },
                },
                sections = {
                    lualine_a = { "filename", "filesize" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "lsp_status" },
                    lualine_z = { "location", "cdate", "ctime"},
                },
                inactive_sections = {
                    lualine_a = {},
                    lualine_b = {},
                    lualine_c = { "filename" },
                    lualine_x = { "location" },
                    lualine_y = {},
                    lualine_z = {},
                },
                tabline = {},
                winbar = {},
                inactive_winbar = {},
                    extensions = {},
            })
        end,
    },
}
