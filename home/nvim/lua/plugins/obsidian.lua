return {
    -- Actively-maintained community fork (the original epwalsh/obsidian.nvim
    -- has been dormant for ~a year). Edits your real Obsidian vault: wikilinks,
    -- daily notes, templates, backlinks, tags, search.
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- pin to latest release tag rather than a moving branch
    ft = "markdown",
    dependencies = {
        "nvim-lua/plenary.nvim",
    },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
        -- obsidian.nvim auto-selects the workspace based on which vault the
        -- current buffer lives in, so both vaults can be active at once.
        workspaces = {
            { name = "personal", path = "~/Documents/Personal-Notes" },
            { name = "school", path = "~/Documents/school/Notes/CU-Obsidian" },
        },

        -- Completion is provided by obsidian.nvim's built-in LSP server, which
        -- flows into nvim-cmp automatically via our cmp-nvim-lsp source. (The
        -- old `completion.nvim_cmp` option is deprecated / removed in 4.0.)

        -- IMPORTANT: render-markdown.nvim handles in-buffer display, so turn
        -- off obsidian's built-in UI to avoid two plugins concealing the same
        -- syntax and clobbering each other.
        ui = { enable = false },

        -- We use the new `:Obsidian <subcommand>` style everywhere (see keys
        -- below), so disable the legacy ObsidianX commands and their warning.
        legacy_commands = false,

        -- The `mappings` opt is deprecated; per-note keymaps are now set in the
        -- enter_note callback via require("obsidian.actions"). Kept as a plain
        -- function() so it's robust to the callback's arg signature.
        -- Checkbox toggle stays on <leader>Ox (obsidian's suggested <leader>ch
        -- would clash with the clangd type-hierarchy bind).
        callbacks = {
            enter_note = function()
                local actions = require("obsidian.actions")
                vim.keymap.set("n", "gf", actions.smart_action,
                    { buffer = true, silent = true, desc = "Obsidian: follow link / smart action" })
                vim.keymap.set("n", "<cr>", actions.smart_action,
                    { buffer = true, silent = true, desc = "Obsidian: smart action" })
                vim.keymap.set("n", "<leader>Ox", actions.toggle_checkbox,
                    { buffer = true, silent = true, desc = "Obsidian: toggle checkbox" })
            end,
        },
    },
    -- <leader>O = Obsidian (kept off <leader>n, which toggles Neotree)
    keys = {
        { "<leader>On", "<cmd>Obsidian new<cr>", desc = "Obsidian: new note" },
        { "<leader>Ot", "<cmd>Obsidian today<cr>", desc = "Obsidian: today's daily note" },
        { "<leader>Oy", "<cmd>Obsidian yesterday<cr>", desc = "Obsidian: yesterday's note" },
        { "<leader>Os", "<cmd>Obsidian search<cr>", desc = "Obsidian: search notes" },
        { "<leader>Oq", "<cmd>Obsidian quick_switch<cr>", desc = "Obsidian: quick switch" },
        { "<leader>Ob", "<cmd>Obsidian backlinks<cr>", desc = "Obsidian: backlinks" },
        { "<leader>Ol", "<cmd>Obsidian links<cr>", desc = "Obsidian: links in note" },
        { "<leader>OT", "<cmd>Obsidian template<cr>", desc = "Obsidian: insert template" },
        { "<leader>Or", "<cmd>Obsidian rename<cr>", desc = "Obsidian: rename note (updates links)" },
    },
}
