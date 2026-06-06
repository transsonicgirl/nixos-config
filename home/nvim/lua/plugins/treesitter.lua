return {
    {
        "nvim-treesitter/nvim-treesitter",
        name = "treesitter",
        branch = "main",
        build = ":TSUpdate",
        priority = 1000,
        config = function()
        require("nvim-treesitter").setup({
            ensure_installed = { "verilog" },
            auto_install = true,
            ignore_install = { "lua", "vim", "vimdoc", "query", "c" },
        })
        end
    },
}
