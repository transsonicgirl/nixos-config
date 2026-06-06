-- Telescope functions
return {
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		build = "make",
	},
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "BurntSushi/ripgrep", "nvim-telescope/telescope-live-grep-args.nvim" },
        cmd = "Telescope",
        keys = {
            { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Telescope find files" },
            { "<leader>fg", "<cmd>lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>", desc = "Telescope live grep" },
            { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Telescope buffers" },
            { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Telescope help tags" },
        },
		config = function()
			local builtin = require("telescope.builtin")
		end,
	},
}
