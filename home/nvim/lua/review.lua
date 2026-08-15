-- PR-review workflow helpers.

-- #2  <leader>yl (visual): yank "absolute/path:START-END" to the unnamed
-- register, e.g. /home/transsonicgirl/foo.py:20-40 (single line -> :N).
local function yank_path_with_lines()
    local path = vim.fn.expand("%:p")
    if path == "" then
        vim.notify("Buffer has no file path", vim.log.levels.WARN)
        return
    end
    -- while the visual-mode mapping fires, "v" is the selection anchor and
    -- "." is the cursor end; order them so start <= end.
    local a = vim.fn.line("v")
    local b = vim.fn.line(".")
    local s, e = math.min(a, b), math.max(a, b)

    local ref
    if s == e then
        ref = string.format("%s:%d", path, s)
    else
        ref = string.format("%s:%d-%d", path, s, e)
    end

    vim.fn.setreg('"', ref) -- unnamed register
    vim.notify("Yanked: " .. ref)
end

vim.keymap.set("x", "<leader>yl", yank_path_with_lines, { desc = "Yank path:lines to unnamed register" })

-- #3  <leader>r: toggle a floating ("picture-in-picture") window in the
-- bottom-right editing <repo root>/tmp/review.md for notes on the PR under
-- review. Auto-creates the file from a checklist template, auto-saves on close.
local review_win = nil
local review_buf = nil

local review_template = {
    "# PR Review Notes",
    "",
    "## Summary",
    "",
    "",
    "## Checklist",
    "- [ ] Correctness — does it do what it claims?",
    "- [ ] Edge cases & error handling",
    "- [ ] Tests cover the change (and actually exercise it)",
    "- [ ] Naming & readability",
    "- [ ] Scope creep / unintended changes",
    "- [ ] Security — input validation, secrets, authz",
    "- [ ] Performance & complexity",
    "- [ ] Docs & comments updated",
    "",
    "## Questions / follow-ups",
    "",
    "",
    "## Blocking issues",
    "",
}

local function close_review()
    -- auto-save notes before closing
    if review_buf and vim.api.nvim_buf_is_valid(review_buf) then
        vim.api.nvim_buf_call(review_buf, function()
            if vim.bo.modified then
                vim.cmd("silent! write")
            end
        end)
    end
    if review_win and vim.api.nvim_win_is_valid(review_win) then
        vim.api.nvim_win_close(review_win, false)
    end
    review_win = nil
end

-- Make sure the review notes are git-ignored, but WITHOUT touching the tracked
-- .gitignore of the repo under review (that would show up as a diff). Instead
-- append to .git/info/exclude, which is local and untracked. No-op if the path
-- is already ignored by any means.
local function ensure_tmp_ignored(root, file)
    -- already ignored (.gitignore, info/exclude, or global)? nothing to do.
    vim.fn.system({ "git", "-C", root, "check-ignore", "-q", file })
    if vim.v.shell_error == 0 then
        return
    end

    local gitdir = vim.fn.systemlist({ "git", "-C", root, "rev-parse", "--absolute-git-dir" })[1]
    if vim.v.shell_error ~= 0 or gitdir == nil or gitdir == "" then
        return
    end
    local exclude = gitdir .. "/info/exclude"

    local lines = {}
    if vim.fn.filereadable(exclude) == 1 then
        lines = vim.fn.readfile(exclude)
    end
    for _, l in ipairs(lines) do
        if l == "/tmp/" then
            return -- pattern already present
        end
    end

    vim.fn.mkdir(gitdir .. "/info", "p")
    table.insert(lines, "/tmp/")
    vim.fn.writefile(lines, exclude)
    vim.notify("Ignored /tmp/ via .git/info/exclude (local, untracked)")
end

local function toggle_review_notes()
    -- if the float is already open, save + close it (toggle)
    if review_win and vim.api.nvim_win_is_valid(review_win) then
        close_review()
        return
    end

    local root = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })[1]
    if vim.v.shell_error ~= 0 or root == nil or root == "" then
        vim.notify("Not inside a git repository", vim.log.levels.WARN)
        return
    end

    local dir = root .. "/tmp"
    vim.fn.mkdir(dir, "p")
    local file = dir .. "/review.md"
    local is_new = vim.fn.filereadable(file) == 0

    ensure_tmp_ignored(root, file)

    review_buf = vim.fn.bufadd(file)
    vim.fn.bufload(review_buf)
    vim.bo[review_buf].buflisted = true

    -- seed the template only when creating the file (never clobber real notes)
    if is_new then
        vim.api.nvim_buf_set_lines(review_buf, 0, -1, false, review_template)
    end

    local width = math.floor(vim.o.columns * 0.5)
    local height = math.floor(vim.o.lines * 0.6)
    -- bottom-right, leaving a margin for the border + cmdline
    local col = math.max(0, vim.o.columns - width - 2)
    local row = math.max(0, vim.o.lines - height - 3)

    review_win = vim.api.nvim_open_win(review_buf, true, {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        title = " PR review notes ",
        title_pos = "center",
    })

    -- q also saves + closes
    vim.keymap.set("n", "q", close_review, { buffer = review_buf, desc = "Save & close review notes" })
end

vim.keymap.set("n", "<leader>r", toggle_review_notes, { desc = "Toggle PR review notes (float)" })
