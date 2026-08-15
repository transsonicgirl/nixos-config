return {
    "anurag3301/nvim-platformio.lua",
    dependencies = {
        "akinsho/nvim-toggleterm.lua",
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim",
    },

    cmd = {
        "Pioinit",
        "Piorun",
        "Piocmd",
        "Piolib",
        "Piomon",
        "Piodebug",
        "Piodb",
    },
    config = function()
        require("platformio").setup({
            -- clangd (not ccls): ccls isn't installed, and you use clangd
            -- everywhere else. clangd also generates compile_commands.json.
            lsp = "clangd",
        })
    end,
}
