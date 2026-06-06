return {
	{ -- MASON (LSP manager)
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{ -- MASON-LSPCONFIG (installs LSPs)
		"williamboman/mason-lspconfig.nvim",
		config = function()
			require("mason-lspconfig").setup({
                ensure_installed = { "clangd", "cmake", "cssls", "html", "harper_ls", "lua_ls", "pylsp", "rust_analyzer" },
                automatic_enable = false,
			})
		end,
	},
	{ -- LSPCONFIG (Allows using LSPs in Neovim)
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Define per-server configs with the new core API.
			local servers = {
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--all-scopes-completion",
						"--suggest-missing-includes",
						"--clang-tidy",
					},
					capabilities = capabilities,
				},
				cmake = { capabilities = capabilities },
				cssls = { capabilities = capabilities },
				html = { capabilities = capabilities },
				ltex = { capabilities = capabilities },
				lua_ls = { capabilities = capabilities },
				rust_analyzer = { capabilities = capabilities },
				pylsp = { capabilities = capabilities },
			}

			for name, cfg in pairs(servers) do
				vim.lsp.config(name, cfg)
			end

			-- Enable all configured servers (can be a list or a single name)
			vim.lsp.enable(vim.tbl_keys(servers))
		end,
	},
}
