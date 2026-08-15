return {
    -- Teaches lua_ls about the Neovim API: the `vim` global, nvim's runtime
    -- types, and other plugins' modules for require() completion.
    --
    -- Replaces neodev.nvim, which folke archived in July 2024. The difference
    -- is when the work happens: neodev pushed the entire runtime plus every
    -- installed plugin into lua_ls's workspace.library at startup, which meant
    -- indexing tens of thousands of files before completion woke up. lazydev
    -- adds library paths on demand as you require() them instead.
    --
    -- NOTE: this only affects Lua files that lua_ls treats as Neovim config.
    -- The Hyprland config at home/dotfiles/hypr/ has its own .luarc.json
    -- pinning the hl.meta.lua stubs, which lua_ls reads natively.
    "folke/lazydev.nvim",
    ft = "lua",
    opts = {
        library = {
            -- luv (vim.uv) type defs, pulled in only for files that mention it
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
    },
}
