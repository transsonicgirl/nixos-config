;;; init.el --- Emacs config, ported from home/nvim -*- lexical-binding: t; -*-

;; Every package below is installed by Nix (programs.emacs.extraPackages in
;; home/transsonicgirl.nix). use-package only configures them; nothing is
;; downloaded at runtime. To add a package: add it to extraPackages, rebuild,
;; then add a use-package block here.

;;; ---------------------------------------------------------------- housekeeping

;; Keep ~/.config/emacs tidy: state goes to var/, config files to etc/.
;; This must load before anything that writes state.
(use-package no-littering
  :demand t
  :config
  (no-littering-theme-backups)
  (setq create-lockfiles nil)
  ;; The config dir is read-only Nix store symlinks, so the Customize UI must
  ;; write somewhere else (same reason lazy-lock.json moved in nvim).
  (setq custom-file (no-littering-expand-etc-file-name "custom.el"))
  (load custom-file 'noerror 'nomessage))

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold (* 32 1024 1024))))
(setq read-process-output-max (* 1024 1024)) ; LSP servers send big payloads

(recentf-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(global-auto-revert-mode 1)

;;; ---------------------------------------------------------------- editing basics

;; spacetabs config
(setq-default indent-tabs-mode nil
              tab-width 4)

;; Auto-indent (RET, `=') uses each mode's own offset, and many default to
;; 2. Set them all to 4. These are defcustoms, so setq before load sticks.
(setq c-ts-mode-indent-offset 4
      nix-ts-mode-indent-offset 4
      lua-ts-mode-indent-offset 4
      cmake-ts-mode-indent-offset 4
      json-ts-mode-indent-offset 4
      js-indent-level 4
      typescript-ts-mode-indent-offset 4
      css-indent-offset 4
      sh-basic-offset 4
      fish-indent-offset 4
      evil-shift-width 4)

;; Emacs' TAB re-indents the line by the major mode's rules instead of
;; inserting indentation: it does nothing when the mode thinks the line is
;; already right, and aligns to the previous line's words in text modes. Make
;; TAB / backspace behave like Vim's expandtab + softtabstop=4 instead.
(defun my/soft-tab ()
  "Indent to the next multiple of `tab-width', or indent the region."
  (interactive)
  (if (use-region-p)
      (indent-rigidly (region-beginning) (region-end) tab-width)
    (tab-to-tab-stop)))

(defun my/soft-backspace ()
  "Delete back to the previous tab stop if only spaces are in the way."
  (interactive)
  (let* ((col (current-column))
         (n (if (zerop (% col tab-width)) tab-width (% col tab-width)))
         (spaces (- (point) (save-excursion (skip-chars-backward " " (- (point) n))
                                            (point)))))
    (if (and (> spaces 1) (not (use-region-p)))
        (delete-char (- spaces))
      (call-interactively #'delete-backward-char))))

(define-minor-mode my/soft-tab-mode
  "TAB and backspace work in `tab-width' steps of spaces."
  :keymap (make-sparse-keymap))
(add-hook 'prog-mode-hook #'my/soft-tab-mode)
(add-hook 'text-mode-hook #'my/soft-tab-mode)

;; line numbers + cursorline
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)
(global-hl-line-mode 1)

(setq scroll-conservatively 101 ; scroll line by line at the window edge, like Vim
      scroll-margin 0)

(setq use-short-answers t
      ring-bell-function #'ignore)

;; GUI: <escape> quits minibuffers and prompts, like it does in Vim.
(keymap-global-set "<escape>" #'keyboard-escape-quit)

;;; ---------------------------------------------------------------- look

(set-face-attribute 'default nil :family "IoskeleyMono Nerd Font" :height 110)

(use-package catppuccin-theme
  :demand t
  :custom (catppuccin-flavor 'mocha)
  :config
  (load-theme 'catppuccin t)
  ;; same cursorline colors as the nvim config
  (set-face-attribute 'hl-line nil :background "#313244")
  (set-face-attribute 'line-number-current-line nil
                      :foreground "#cba6f7" :background "#313244" :weight 'bold))

(use-package nerd-icons
  :demand t
  :custom (nerd-icons-font-family "Symbols Nerd Font Mono"))

(use-package doom-modeline
  :demand t
  :config
  ;; lualine showed date + time on the right
  (setq display-time-format "%Y-%m-%d %H:%M"
        display-time-default-load-average nil)
  (display-time-mode 1)
  (doom-modeline-mode 1))

;; Indentation guides (indent-blankline). Tree-sitter aware where available.
(use-package indent-bars
  :hook (prog-mode . indent-bars-mode)
  :custom (indent-bars-treesit-support t))

;;; ---------------------------------------------------------------- evil

(use-package undo-fu)

(use-package evil
  :demand t
  :init
  ;; evil-collection supplies the bindings for non-file buffers instead
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-undo-system 'undo-fu
        ;; Vim states in the minibuffer too, so pickers behave like
        ;; telescope: type in insert, ESC to normal (j/k/gg/G), ESC again quits
        evil-want-minibuffer t)
  :config
  (evil-mode 1)
  ;; `:' and the pickers always open ready to type. The minibuffer buffer is
  ;; reused between prompts, so otherwise it keeps the state you left it in
  ;; (normal, after ESC). Depth 90 runs this after evil's own setup.
  (add-hook 'minibuffer-setup-hook #'evil-insert-state 90))

;; Vim keys in Dired, Magit, help, vterm, the dashboard, etc.
(use-package evil-collection
  :after evil
  :demand t
  :init (setq evil-collection-setup-minibuffer t)
  :config (evil-collection-init))

;; Read-only popups (diagnostics list, LSP docs, help) close with ESC as well as q.
(define-minor-mode my/esc-quits-mode
  "ESC closes this popup window, like `q'."
  :keymap (make-sparse-keymap)
  (evil-normalize-keymaps))
(evil-define-key '(normal motion) my/esc-quits-mode-map (kbd "<escape>") #'quit-window)
(dolist (hook '(flymake-diagnostics-buffer-mode-hook
                flymake-project-diagnostics-mode-hook
                help-mode-hook))
  (add-hook hook #'my/esc-quits-mode))
;; eldoc's doc buffer (K) is a plain special-mode buffer, so match it by name
(add-hook 'special-mode-hook
          (lambda () (when (string-match-p "eldoc" (buffer-name)) (my/esc-quits-mode))))

;; Soft tabs (defined under editing basics). <tab> as well as TAB so this
;; outranks modes that bind <tab>, like markdown-mode's heading cycling.
(evil-define-key 'insert my/soft-tab-mode-map
  (kbd "TAB") #'my/soft-tab
  (kbd "<tab>") #'my/soft-tab
  (kbd "DEL") #'my/soft-backspace
  (kbd "<backspace>") #'my/soft-backspace)

;; Multiple cursors. evil-collection puts the commands under `g.'
;; (g.a = cursor on every match, g.q = remove all, g.n / g.N = add on next /
;; previous match). C-n / C-p are the vim-visual-multi style shortcuts.
(use-package evil-mc
  :demand t
  :after evil
  :config
  (evil-define-key* '(normal visual) evil-mc-key-map
    (kbd "C-n") #'evil-mc-make-and-goto-next-match
    (kbd "C-p") #'evil-mc-make-and-goto-prev-match)
  (evil-define-key* 'normal evil-mc-key-map (kbd "<escape>") #'my/evil-mc-escape)
  (global-evil-mc-mode 1))

(defun my/evil-mc-escape ()
  "Drop the extra cursors if there are any, otherwise do what ESC does here.
evil-mc's keymap outranks the others, so without the fallback this would
shadow ESC in pickers and popups."
  (interactive)
  (if (evil-mc-has-cursors-p)
      (evil-mc-undo-all-cursors)
    (let ((evil-mc-mode nil))
      (call-interactively (key-binding [escape])))))

;; nvim's built-in gc / gcc / gc{motion} comment toggle (always linewise).
(evil-define-operator my/evil-comment (beg end)
  "Toggle comments on the lines from BEG to END."
  :type line
  :move-point nil
  (comment-or-uncomment-region beg end))
(evil-define-key '(normal visual) 'global "gc" #'my/evil-comment)

;; Built in since Emacs 30. `SPC' then wait shows the leader map.
(which-key-mode 1)

;;; ---------------------------------------------------------------- completion UI (telescope)

(use-package vertico :demand t :config (vertico-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia :demand t :config (marginalia-mode 1))

(use-package consult
  :defer t
  :init
  ;; LSP references / definitions open in the consult picker
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)
  :config
  ;; consult's default ripgrep args include --search-zip, which decompresses
  ;; archives while searching. Drop it and skip archives entirely.
  (setq consult-ripgrep-args
        (string-replace "--search-zip"
                        "--glob=!*.zip --glob=!*.tar --glob=!*.tar.* --glob=!*.tgz"
                        consult-ripgrep-args)))

;;; ---------------------------------------------------------------- tree-sitter

;; Grammars come from Nix (treesit-grammars.with-all-grammars), so never try
;; to compile one. treesit-auto swaps e.g. python-mode -> python-ts-mode
;; whenever the grammar loads.
(setq treesit-font-lock-level 4) ; richest highlighting, closest to nvim-treesitter

(use-package treesit-auto
  :demand t
  :custom (treesit-auto-install nil)
  :config
  (treesit-auto-add-to-auto-mode-alist 'all)
  (global-treesit-auto-mode 1))

(use-package nix-ts-mode :mode "\\.nix\\'")

;; Languages Emacs has no tree-sitter mode for. Fish has a grammar but no
;; Emacs mode uses it, so fish-mode's regex highlighting + fish-lsp it is.
(use-package fish-mode :mode ("\\.fish\\'" "/fish_funced\\..*\\'"))
(use-package git-modes :defer t)        ; .gitignore, .gitconfig, .gitattributes
(use-package hyprlang-ts-mode :mode "/hypr/.*\\.conf\\'")

;;; ---------------------------------------------------------------- C / C++

;; nvim indented C/C++ with Vim's cindent (default cinoptions), not
;; tree-sitter. BSD is the closest built-in c-ts-mode style; on top of it,
;; the cindent defaults it lacks:
;;   case labels one level inside switch                       (cino :s)
;;   public:/private: one level inside the class, members two  (cino gs, hs)
;;   continuation lines in an unclosed ( two levels in          (cino (2s)
;; c-ts-mode wants the rules wrapped in their language, despite its docstring.
(defun my/c-ts-after-access-specifier-p (node parent bol &rest _)
  "Non-nil if NODE is a class member below a public:/private: label."
  (and (treesit-node-match-p parent "field_declaration_list")
       (not (and node (treesit-node-match-p
                       node (rx bos (or "access_specifier" "}") eos))))
       (seq-some (lambda (child)
                   (and (< (treesit-node-start child) bol)
                        (treesit-node-match-p child "access_specifier")))
                 (treesit-node-children parent t))))

(defun my/c-ts-after-access-label (_node _parent bol &rest _)
  "Start of the public:/private: label on the line above BOL, if any.
Reads the text, not the parse tree, so it also works while the class is
half-typed and doesn't parse yet."
  (save-excursion
    (goto-char bol)
    (forward-line -1)
    (back-to-indentation)
    (and (looking-at (rx (or "public" "private" "protected") (* blank) ":" (* blank) eol))
         (point))))

(defun my/c-ts-open-paren-bol (_node _parent bol &rest _)
  "Indentation start of the line holding the unclosed ( around BOL, if any.
Both the matcher and the anchor of the continuation-line rule."
  (when-let* ((open (nth 1 (save-excursion (syntax-ppss bol))))
              ((eq (char-after open) ?\()))
    (save-excursion (goto-char open) (back-to-indentation) (point))))

(defun my/c-ts-double-offset (&rest _)
  (* 2 c-ts-indent-offset))

(defun my/c-ts-indent-style ()
  (let ((lang (if (derived-mode-p 'c++-ts-mode) 'cpp 'c)))
    `((,lang
       ((node-is "case_statement") standalone-parent c-ts-indent-offset)
       ((node-is "access_specifier") parent-bol c-ts-indent-offset)
       (my/c-ts-after-access-specifier-p parent-bol my/c-ts-double-offset)
       (my/c-ts-after-access-label my/c-ts-after-access-label c-ts-indent-offset)
       (my/c-ts-open-paren-bol my/c-ts-open-paren-bol my/c-ts-double-offset)
       ,@(cdar (c-ts-mode--simple-indent-rules lang 'bsd))))))

(setq c-ts-mode-indent-style #'my/c-ts-indent-style)

;; Comment continuation (Vim's formatoptions=jcroql). An unclosed /** breaks
;; the tree-sitter parse, so RET/o/O continue comments from the text, through
;; c-ts-mode's `comment-line-break-function' (normally only on M-j).
(defun my/c-comment-break-add-space (&rest _)
  "After a bare `/*', c-ts-mode continues with ` *' and no space; add one."
  (when (looking-back "^[ \t]*\\*" (line-beginning-position))
    (insert " ")))

(defun my/c-close-comment ()
  "Typing / on a bare ` * ' line closes the comment as ` */'."
  (when (and (eq last-command-event ?/)
             (looking-back "^[ \t]*\\* /" (line-beginning-position)))
    (delete-char -2)
    (insert "/")))

;; Vim's C defaults: `_' is part of a word (iskeyword), so w/e/b/ciw/* treat
;; foo_bar as one word; gq wraps at 79 when textwidth=0; C comments with //
;; (nvim's commentstring), not /* */.
(add-hook 'c-ts-base-mode-hook
          (lambda ()
            (modify-syntax-entry ?_ "w")
            (setq-local fill-column 79)
            (c-ts-mode-toggle-comment-style -1)
            (add-function :after (local 'comment-line-break-function)
                          #'my/c-comment-break-add-space)
            (add-hook 'post-self-insert-hook #'my/c-close-comment nil t)))

(defun my/c-in-own-line-comment-p ()
  "Non-nil if point is in a comment that starts its line.
Trailing comments (`foo(); // note') don't count, so RET after one
starts a normal code line."
  (let ((ppss (syntax-ppss)))
    (and (nth 4 ppss)
         (save-excursion
           (goto-char (nth 8 ppss))
           (looking-back "^[ \t]*" (line-beginning-position))))))

(defun my/c-line-ends-in-comment-p (&optional n)
  "Non-nil if line N lines from this one ends inside an own-line comment."
  (save-excursion
    (forward-line (or n 0))
    (end-of-line)
    (my/c-in-own-line-comment-p)))

(defun my/c-newline ()
  "Newline that continues the comment (` * ', `//') when inside one."
  (interactive)
  (if (my/c-in-own-line-comment-p)
      (funcall comment-line-break-function)
    (newline nil t)))

(defun my/c-open-comment-line ()
  "Open a comment line after this one and enter insert state."
  (end-of-line)
  (evil-insert-state)
  (funcall comment-line-break-function))

(defun my/c-open-below ()
  "Like `evil-open-below', but continue the comment if the line ends in one."
  (interactive)
  (if (my/c-line-ends-in-comment-p)
      (my/c-open-comment-line)
    (call-interactively #'evil-open-below)))

(defun my/c-open-above ()
  "Like `evil-open-above', but continue the comment if inside one."
  (interactive)
  (if (and (save-excursion (back-to-indentation) (evil-in-comment-p))
           (my/c-line-ends-in-comment-p -1))
      (progn (forward-line -1) (my/c-open-comment-line))
    (call-interactively #'evil-open-above)))

(defun my/c-join-comment-leader (&rest _)
  "After `join-line' inside a comment, drop the joined line's ` * ' or `//'.
evil's J joins with `join-line'; this is Vim's formatoptions+=j."
  (when (and (derived-mode-p 'c-ts-base-mode)
             (nth 4 (syntax-ppss))
             (looking-at "[ \t]*\\(?:\\*\\|//+\\)\\(?:[ \t]+\\|$\\)"))
    (replace-match (if (eolp) "" " "))))
(advice-add 'join-line :after #'my/c-join-comment-leader)

;; ClangdSwitchSourceHeader: clangd knows the project layout (include/ vs
;; src/), which `ff-find-other-file' only guesses at.
(defun my/switch-source-header ()
  "Jump between header and source, through clangd when it's running."
  (interactive)
  (if-let* (((eglot-managed-p))
            (uri (jsonrpc-request (eglot-current-server)
                                  :textDocument/switchSourceHeader
                                  (list :uri (eglot-path-to-uri buffer-file-name)))))
      (find-file (eglot-uri-to-path uri))
    (ff-find-other-file)))

(with-eval-after-load 'c-ts-mode
  (keymap-set c-ts-base-mode-map "RET" #'my/c-newline)
  (evil-define-key 'normal c-ts-base-mode-map
    "o" #'my/c-open-below
    "O" #'my/c-open-above))

;;; ---------------------------------------------------------------- markdown rendering

;; render-markdown.nvim look with scaled headings, images and LaTeX; the
;; renderer lives in lisp/md-render.el. `my/markdown-render-mode' (SPC t m)
;; switches between rendered and source.
(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
(autoload 'my/markdown-render-mode "md-render" nil t)

(use-package markdown-mode
  :defer t
  :custom
  (markdown-fontify-code-blocks-natively t)      ; code blocks use their language's highlighting
  (markdown-enable-math t)
  (markdown-enable-wiki-links t)                 ; Obsidian [[links]]
  (markdown-max-image-size '(800 . 600))
  :config
  ;; Heading sizes, as a user-theme layer on top of catppuccin: the theme's
  ;; heading specs replace markdown-mode's own (`markdown-header-scaling' and
  ;; use-package's :custom-face have no effect).
  (custom-theme-set-faces
   'user
   '(markdown-header-face-1 ((t (:height 1.8 :weight bold))))
   '(markdown-header-face-2 ((t (:height 1.5 :weight bold))))
   '(markdown-header-face-3 ((t (:height 1.3 :weight bold))))
   '(markdown-header-face-4 ((t (:height 1.2 :weight bold))))
   '(markdown-header-face-5 ((t (:height 1.1 :weight bold))))
   '(markdown-header-face-6 ((t (:height 1.05 :weight bold)))))
  :hook (markdown-mode . my/markdown-render-mode))

;; LaTeX math ($...$, $$...$$, \[...\]) rendered to SVG by MathJax. No TeX
;; install needed; the `math-preview' program comes from home.packages.
(use-package math-preview :commands (math-preview-all math-preview-clear-all))

;;; ---------------------------------------------------------------- LSP (eglot, built in)

;; Servers are the same ones nvim uses, installed in modules/dev.nix.
(use-package eglot
  :hook ((c-ts-mode c++-ts-mode c-mode c++-mode
          python-ts-mode python-mode
          lua-ts-mode rust-ts-mode nix-ts-mode cmake-ts-mode
          markdown-mode markdown-ts-mode fish-mode)
         . eglot-ensure)
  :custom
  (eglot-autoshutdown t)                ; stop the server with its last buffer
  (eglot-events-buffer-config '(:size 0 :format full))
  ;; Emacs does the indenting: clangd's on-type formatting re-indents each
  ;; RET LLVM-style (2 spaces) and mangles half-typed /** comments. nvim
  ;; never enabled it either.
  (eglot-ignored-server-capabilities '(:documentOnTypeFormattingProvider))
  :config
  (add-to-list 'eglot-server-programs
               '((c-ts-mode c++-ts-mode c-mode c++-mode)
                 . ("clangd" "--background-index" "--all-scopes-completion"
                    "--suggest-missing-includes" "--clang-tidy")))
  (add-to-list 'eglot-server-programs '((nix-ts-mode nix-mode) . ("nil")))
  (add-to-list 'eglot-server-programs '(fish-mode . ("fish-lsp" "start")))
  (add-to-list 'eglot-server-programs
               '((markdown-mode markdown-ts-mode) . ("harper-ls" "--stdio")))
  ;; nvim's default LSP maps. evil-collection binds gr alone to references;
  ;; free it up as a prefix.
  (evil-define-key 'normal eglot-mode-map
    "K" #'eldoc-doc-buffer
    "gr" nil
    "grn" #'eglot-rename
    "gra" #'eglot-code-actions
    "grr" #'xref-find-references
    "gri" #'eglot-find-implementation
    "grt" #'eglot-find-typeDefinition
    "gO" #'imenu))

;; nvim's default ]d / [d diagnostic jumps
(evil-define-key 'normal flymake-mode-map
  "]d" #'flymake-goto-next-error
  "[d" #'flymake-goto-prev-error)

;; Popup completion (nvim-cmp). Manual like the nvim config: C-SPC opens it,
;; and typing `.', `->' or `::' in an LSP buffer opens it automatically.
(use-package corfu
  :demand t
  :custom
  (corfu-auto nil)
  (corfu-cycle t)
  ;; nvim-cmp's confirm({ select = false }): nothing selected on open
  (corfu-preselect 'prompt)
  :bind (:map corfu-map
              ("C-e" . corfu-quit)
              ("C-f" . corfu-popupinfo-scroll-up)
              ("C-b" . corfu-popupinfo-scroll-down))
  :config
  ;; ...and RET only accepts an item picked with C-n / C-p; otherwise it
  ;; falls through to a normal newline.
  (keymap-set corfu-map "RET"
              `(menu-item "" corfu-insert
                          :filter ,(lambda (cmd) (and (>= corfu--index 0) cmd))))
  (global-corfu-mode 1)
  (require 'corfu-popupinfo)
  (corfu-popupinfo-mode 1)
  (evil-define-key 'insert 'global (kbd "C-SPC") #'completion-at-point))

(defun my/complete-after-member-access ()
  "Open completion after `.', `->' or `::'."
  (when (and (memq last-command-event '(?. ?> ?:))
             (looking-back "\\.\\|->\\|::" (- (point) 2)))
    (let ((completion-fail-discreetly t))
      (completion-at-point))))

(add-hook 'eglot-managed-mode-hook
          (lambda ()
            (if (eglot-managed-p)
                (add-hook 'post-self-insert-hook #'my/complete-after-member-access nil t)
              (remove-hook 'post-self-insert-hook #'my/complete-after-member-access t))))

;; Formatting (none-ls). Manual on SPC g f, like nvim; uses the formatters
;; from modules/dev.nix (clang-format, black, isort, stylua, shfmt).
(use-package apheleia
  :commands apheleia-format-buffer
  :config
  (setf (alist-get 'python-mode apheleia-mode-alist) '(isort black))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(isort black)))

;;; ---------------------------------------------------------------- dired

(use-package dired
  :custom
  (dired-listing-switches "-alh --group-directories-first")
  (dired-dwim-target t)                 ; copy/move target = the other dired window
  (dired-kill-when-opening-new-dired-buffer t)
  (dired-auto-revert-buffer t)
  :config
  (require 'dired-x)
  ;; neo-tree style: h goes up a directory, l opens the file/directory
  (evil-collection-define-key 'normal 'dired-mode-map
    "h" #'dired-up-directory
    "l" #'dired-find-file))

(use-package nerd-icons-dired :hook (dired-mode . nerd-icons-dired-mode))

;; neo-tree replacement: a dired buffer pinned to the left side.
(use-package dired-subtree :after dired)
(use-package dired-sidebar
  :commands dired-sidebar-toggle-sidebar
  :custom
  (dired-sidebar-theme 'nerd-icons)
  (dired-sidebar-should-follow-file t))

;;; ---------------------------------------------------------------- git

(use-package magit :commands (magit-status magit-commit-create magit-blame-addition
                              magit-log-current magit-push magit-pull))

;; gitsigns: hunk markers in the fringe, kept in sync with magit
(use-package diff-hl
  :demand t
  :config
  (global-diff-hl-mode 1)
  (require 'diff-hl-flydiff)
  (diff-hl-flydiff-mode 1)
  (unless (display-graphic-p)
    (require 'diff-hl-margin)
    (diff-hl-margin-mode 1))
  (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

;;; ---------------------------------------------------------------- dashboard (alpha)

(use-package dashboard
  :demand t
  :config
  (setq dashboard-startup-banner (expand-file-name "banner.txt" user-emacs-directory)
        dashboard-banner-logo-title nil
        dashboard-center-content t
        dashboard-vertically-center-content t
        dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-projects-backend 'project-el
        dashboard-items '((recents . 5) (projects . 5))
        dashboard-navigator-buttons
        `(((,(nerd-icons-mdicon "nf-md-file_search") " Find file" "SPC f f"
            (lambda (&rest _) (consult-fd)))
           (,(nerd-icons-mdicon "nf-md-text_search") " Ripgrep" "SPC f g"
            (lambda (&rest _) (consult-ripgrep)))
           (,(nerd-icons-mdicon "nf-md-history") " Recent" "SPC f r"
            (lambda (&rest _) (consult-recent-file)))
           (,(nerd-icons-mdicon "nf-md-exit_run") " Quit" "save all and exit"
            (lambda (&rest _) (save-buffers-kill-terminal)))))
        dashboard-startupify-list '(dashboard-insert-banner
                                    dashboard-insert-newline
                                    dashboard-insert-navigator
                                    dashboard-insert-newline
                                    dashboard-insert-items
                                    dashboard-insert-newline
                                    dashboard-insert-init-info))
  (set-face-attribute 'dashboard-text-banner nil :foreground "#cba6f7")
  (dashboard-setup-startup-hook)
  ;; also show it in new emacsclient frames
  (setq initial-buffer-choice (lambda () (get-buffer-create dashboard-buffer-name))))

;;; ---------------------------------------------------------------- claude code

(use-package claude-code
  :commands (claude-code-run claude-code-transient claude-code-get-buffer))

;; Open the session in a right-hand panel at 30% width, like claude-code.nvim.
(add-to-list 'display-buffer-alist
             '("\\`\\*claude:"
               (display-buffer-in-side-window)
               (side . right)
               (window-width . 0.3)))

(defun my/claude-toggle ()
  "Show, hide, or start Claude Code for the current project."
  (interactive)
  (require 'claude-code)
  (let* ((buf (claude-code-get-buffer))
         (win (and buf (get-buffer-window buf))))
    (cond (win (delete-window win))
          (buf (pop-to-buffer buf))
          (t (claude-code-run)))))

(keymap-global-set "C-," #'my/claude-toggle)

;;; ---------------------------------------------------------------- terminal

;; SPC t t: one vterm (fish) per folder, in a bottom panel at 30% height.
;; Pin fish rather than inheriting $SHELL, which depends on how Emacs started.
(setq vterm-shell "fish")
(add-to-list 'display-buffer-alist
             '("\\`\\*vterm: "
               (display-buffer-in-side-window)
               (side . bottom)
               (window-height . 0.3)))

(defun my/vterm-toggle ()
  "Hide the terminal panel, or open a terminal in the current buffer's folder.
Reuses that folder's terminal if one is already running."
  (interactive)
  (if-let* ((win (seq-find (lambda (w) (string-prefix-p "*vterm: " (buffer-name (window-buffer w))))
                           (window-list))))
      (delete-window win)
    (let* ((name (format "*vterm: %s*" (abbreviate-file-name default-directory)))
           (buf (get-buffer name)))
      (if buf (pop-to-buffer buf) (vterm-other-window name))
      (evil-insert-state))))

;;; ---------------------------------------------------------------- keys

;; tab controls
(evil-define-key 'normal 'global
  "]t" #'tab-bar-switch-to-next-tab
  "[t" #'tab-bar-switch-to-prev-tab
  (kbd "C-t") #'tab-new
  ;; gitsigns hunk navigation
  "]c" #'diff-hl-next-hunk
  "[c" #'diff-hl-previous-hunk)

;; SPC leader in normal/visual/motion; M-SPC reaches it from insert mode.
(use-package general
  :demand t
  :config
  (general-create-definer my/leader
    :states '(normal visual motion)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "M-SPC")

  (my/leader
    "a"  '(dashboard-open :wk "dashboard")
    "v"  '(split-window-right :wk "vertical split")
    "n"  '(dired-sidebar-toggle-sidebar :wk "file sidebar")
    "d"  '(dired-jump :wk "dired here")
    "e"  '(flymake-show-buffer-diagnostics :wk "diagnostics")
    "s"  '(my/switch-source-header :wk "switch .h/.cpp")
    "?"  '(which-key-show-major-mode :wk "mode keys")

    "f"  '(:ignore t :wk "find")
    "ff" '(consult-fd :wk "files")
    "fg" '(consult-ripgrep :wk "ripgrep")
    "fb" '(consult-buffer :wk "buffers")
    "fr" '(consult-recent-file :wk "recent files")
    "fh" '(describe-symbol :wk "help")
    ;; same searches, but ask which directory to search first
    "fF" '((lambda () (interactive) (consult-fd t)) :wk "files in dir...")
    "fG" '((lambda () (interactive) (consult-ripgrep t)) :wk "ripgrep in dir...")

    "g"  '(:ignore t :wk "git / lsp")
    "gg" '(magit-status :wk "status")
    "gc" '(magit-commit-create :wk "commit")
    "gb" '(magit-blame-addition :wk "blame")
    "gl" '(magit-log-current :wk "log")
    "gp" '(magit-push :wk "push")
    "gP" '(magit-pull :wk "pull")
    "gd" '(eglot-find-declaration :wk "goto declaration")
    "gD" '(xref-find-definitions :wk "goto definition")
    "gf" '(apheleia-format-buffer :wk "format buffer")

    "h"  '(:ignore t :wk "hunks")
    "hs" '(diff-hl-stage-current-hunk :wk "stage hunk")
    "hr" '(diff-hl-revert-hunk :wk "reset hunk")
    "hp" '(diff-hl-show-hunk :wk "preview hunk")

    "t"  '(:ignore t :wk "terminal / toggles")
    "tt" '(my/vterm-toggle :wk "toggle terminal")
    "tm" '(my/markdown-render-mode :wk "markdown render")

    "c"  '(:ignore t :wk "claude")
    "cc" '(my/claude-toggle :wk "toggle")
    "cm" '(claude-code-transient :wk "menu")))

;;; init.el ends here
