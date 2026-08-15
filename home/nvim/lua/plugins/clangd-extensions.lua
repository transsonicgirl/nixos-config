return {
    -- C/C++ power tools on top of clangd (AST, type hierarchy, symbol info,
    -- memory usage) using clangd's non-standard LSP extensions.
    -- NOTE: clangd itself is configured in lsp-config.lua; this plugin does
    -- NOT set up the server, it only adds the extra commands.
    "p00f/clangd_extensions.nvim",
    -- Loaded at startup (not ft-lazy) because completions.lua pulls in its
    -- cmp_scores comparator when nvim-cmp configures at startup.
    lazy = false,
    opts = {},
    config = function(_, opts)
        require("clangd_extensions").setup(opts)

        local map = vim.keymap.set
        map("n", "<leader>ca", "<cmd>ClangdAST<cr>", { desc = "Clangd: AST", silent = true })
        map("x", "<leader>ca", ":ClangdAST<cr>", { desc = "Clangd: AST (selection)", silent = true })
        map("n", "<leader>ci", "<cmd>ClangdSymbolInfo<cr>", { desc = "Clangd: symbol info", silent = true })
        map("n", "<leader>ch", "<cmd>ClangdTypeHierarchy<cr>", { desc = "Clangd: type hierarchy", silent = true })
        map("n", "<leader>cm", "<cmd>ClangdMemoryUsage<cr>", { desc = "Clangd: memory usage", silent = true })
    end,
}
