return {
	{
		"nvimtools/none-ls.nvim",
		config = function()
			local null_ls = require("null-ls")
			null_ls.setup({
				sources = {
					null_ls.builtins.formatting.stylua, -- lua
					null_ls.builtins.formatting.clang_format, -- c/c++
					null_ls.builtins.formatting.black, -- python
					null_ls.builtins.formatting.isort, -- python
					null_ls.builtins.formatting.shfmt, -- bash/sh
					null_ls.builtins.formatting.fish_indent, -- fish
				},
			})

			vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, { desc = "Auto-format" })
		end,
	},
}
