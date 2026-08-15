return {
	{
		"hrsh7th/cmp-nvim-lsp",
	},
	{ -- LUASNIP: snippet engine
		"L3MON4D3/LuaSnip",
		dependencies = {
			"saadparwaiz1/cmp_luasnip", -- more snippet engine
			"rafamadriz/friendly-snippets", -- snippet library
		},
		build = "make install_jsregexp",
	},

	{ -- NVIM-CMP: snippet UI
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-cmdline",
			"chrisgrieser/cmp-nerdfont",
			"mtoohey31/cmp-fish",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			-- ensures clangd_extensions.cmp_scores is on the runtimepath
			-- before this config runs, so the comparator below can load
			"p00f/clangd_extensions.nvim",
		},
		config = function()
			-- Set up nvim-cmp.
			local cmp = require("cmp")
			local lsp_types = require("cmp.types").lsp
			require("luasnip.loaders.from_vscode").lazy_load()

			-- Completion sort order. Kind-priority first (methods/props/fields
			-- above functions/vars, snippets last), then clangd's own scorer
			-- (only when clangd_extensions is available), then cmp's defaults.
			local comparators = {
				function(entry1, entry2)
					local kind_priority = {
						[lsp_types.CompletionItemKind.Method] = 100,
						[lsp_types.CompletionItemKind.Property] = 90,
						[lsp_types.CompletionItemKind.Field] = 80,
						[lsp_types.CompletionItemKind.Function] = 70,
						[lsp_types.CompletionItemKind.Variable] = 60,
						[lsp_types.CompletionItemKind.Snippet] = 0,
					}
					local kind1 = kind_priority[entry1:get_kind()] or 0
					local kind2 = kind_priority[entry2:get_kind()] or 0
					if kind1 ~= kind2 then
						return kind1 > kind2
					end
				end,
				cmp.config.compare.offset,
				cmp.config.compare.exact,
				cmp.config.compare.score,
				cmp.config.compare.kind,
				cmp.config.compare.sort_text,
				cmp.config.compare.length,
				cmp.config.compare.order,
			}
			-- clangd_extensions.cmp_scores ranks clangd completions by clangd's
			-- own score. Insert it just after the kind-priority pass so it wins
			-- ties within a kind. Guarded so cmp still works if the plugin is gone.
			local ok_clangd_scores, clangd_scores = pcall(require, "clangd_extensions.cmp_scores")
			if ok_clangd_scores then
				table.insert(comparators, 2, clangd_scores)
			end

			cmp.setup({
				snippet = {
					-- REQUIRED - you must specify a snippet engine
					expand = function(args)
						require("luasnip").lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = false }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
				}),
				completion = {
					autocomplete = false,
				},
				sources = cmp.config.sources({
					-- group_index 0 lets lazydev's require() path completions
					-- replace lua_ls's weaker ones rather than sit alongside them
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
                    { name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "nerdfont" },
					{ name = "fish" },
					{ name = "nvim_lsp_signature_help" },
				}),
				sorting = {
					comparators = comparators,
				},
				formatting = {
					fields = { "abbr", "kind", "menu" },
					max_width = 100,
					format = function(entry, vim_item)
						if entry.source.name == "nvim_lsp" then
							vim_item.menu = "LSP"
						elseif entry.source.name == "buffer" then
							vim_item.menu = "BUF"
						elseif entry.source.name == "path" then
							vim_item.menu = "PTH"
						elseif entry.source.name == "nerdfont" then
							vim_item.menu = "FNT"
						elseif entry.source.name == "fish" then
							vim_item.menu = "FSH"
						end
						return vim_item
					end,
				},
			})

			-- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
				}, {
					{ name = "cmdline" },
				}),
				matching = { disallow_symbol_nonprefix_matching = false },
			})

			-- NOTE: LSP servers are configured in lsp-config.lua (the single
			-- source of truth). They used to be re-declared here too, but that
			-- duplicate set a weaker clangd (no --clang-tidy) and clobbered the
			-- real config depending on plugin load order. cmp capabilities are
			-- still applied there via cmp_nvim_lsp.default_capabilities().

			vim.api.nvim_create_autocmd("TextChangedI", {
				group = vim.api.nvim_create_augroup("CmpTriggerOnDotArrow", { clear = true }),
				pattern = "*",
				callback = function()
					local line = vim.api.nvim_get_current_line()
					local col = vim.api.nvim_win_get_cursor(0)[2]
					-- Check one char before and two chars before cursor
					local char_before = line:sub(col, col)
					local chars_before = line:sub(col - 1, col)
					if char_before == "." or chars_before == "->" or chars_before == "::" then
						cmp.complete()
					end
				end,
			})
		end,
	},
}
