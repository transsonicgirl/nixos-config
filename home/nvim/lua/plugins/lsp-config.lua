return {
	{ -- LSPCONFIG (default server configs + the vim.lsp.config/enable API)
		-- Language servers themselves are installed declaratively via Nix
		-- (modules/dev.nix), not mason: mason ships generic-Linux binaries that
		-- can't run on NixOS without an FHS shim. Nix packages are patchelf'd
		-- to run natively.
		"neovim/nvim-lspconfig",
		lazy = false,
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Per-server configs via the nvim 0.11+ core API.
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
				lua_ls = { capabilities = capabilities },
				pylsp = { capabilities = capabilities },
				rust_analyzer = { capabilities = capabilities },
				nil_ls = { capabilities = capabilities }, -- Nix
				harper_ls = { capabilities = capabilities }, -- prose/grammar
			}

			for name, cfg in pairs(servers) do
				vim.lsp.config(name, cfg)
			end

			vim.lsp.enable(vim.tbl_keys(servers))
		end,
	},
}
