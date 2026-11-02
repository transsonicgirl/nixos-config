;;; md-render.el --- render-markdown.nvim look for markdown-mode -*- lexical-binding: t; -*-

;; `my/markdown-render-mode' draws markdown the way render-markdown.nvim does
;; with its default settings, plus what a GUI adds: scaled headings, inline
;; images and typeset LaTeX.
;;
;; Like render-markdown, part of the buffer is always plain source: the cursor
;; line in normal state, the selected lines in visual state, and everything
;; in insert state. All the rendering is font-lock text properties (`display',
;; `invisible', faces), so the source range is simply re-fontified with
;; `markdown-hide-markup' off, which every renderer below checks. Math and
;; images are overlays whose `display' is stashed while they're in the range.

(require 'cl-lib)
(require 'markdown-mode)
(require 'nerd-icons)

(defvar font-lock-beg)
(defvar font-lock-end)
(defvar evil-state)
(defvar evil-visual-beginning)
(defvar evil-visual-end)
(defvar my/markdown-render-mode)
(declare-function evil-visual-state-p "evil-states")
(declare-function math-preview-all "math-preview")
(declare-function math-preview-clear-all "math-preview")

;;;; Look (catppuccin mocha, as in render-markdown's catppuccin integration)

(defgroup md-render nil "render-markdown.nvim look for markdown-mode." :group 'markdown)

(defface md-render-h1 '((t :background "#493446" :extend t)) "H1 band.")
(defface md-render-h2 '((t :background "#4a3c40" :extend t)) "H2 band.")
(defface md-render-h3 '((t :background "#4a4548" :extend t)) "H3 band.")
(defface md-render-h4 '((t :background "#394545" :extend t)) "H4 band.")
(defface md-render-h5 '((t :background "#2f4054" :extend t)) "H5 band.")
(defface md-render-h6 '((t :background "#3c3e58" :extend t)) "H6 band.")
(defface md-render-rule '((t :strike-through "#6c7086")) "Horizontal rules.")
(defface md-render-dim '((t :foreground "#6c7086")) "Table borders.")
(defface md-render-unchecked '((t :foreground "#7f849c")) "Unchecked box.")
(defface md-render-checked '((t :foreground "#a6e3a1")) "Checked box.")
(defface md-render-todo '((t :foreground "#f9e2af")) "In-progress box.")
(defface md-render-info '((t :foreground "#89b4fa")) "Note/info callouts.")
(defface md-render-success '((t :foreground "#a6e3a1")) "Tip/success callouts.")
(defface md-render-hint '((t :foreground "#94e2d5")) "Important/example callouts.")
(defface md-render-warn '((t :foreground "#f9e2af")) "Warning/question callouts.")
(defface md-render-error '((t :foreground "#f38ba8")) "Caution/danger callouts.")
(defface md-render-quote '((t :foreground "#7f849c")) "Quote callouts.")

(custom-theme-set-faces
 'user
 ;; full-width block background, kept on source lines like render-markdown
 '(markdown-code-face ((t (:background "#181825" :extend t))))
 '(markdown-pre-face ((t (:background "#181825" :extend t))))
 '(markdown-inline-code-face ((t (:background "#313244" :extend nil)))))

(setq markdown-list-item-bullets '("●" "○" "◆" "◇")
      markdown-blockquote-display-char '("▋" "┃" ">")
      markdown-hr-display-char nil        ; md-render--hrs draws rules instead
      markdown-list-indent-width 2)       ; nesting level → bullet, as in the nvim plugin

(defconst md-render-heading-icons '("󰲡 " "󰲣 " "󰲥 " "󰲧 " "󰲩 " "󰲫 "))

(defconst md-render-callouts
  ;; type → (icon title face), render-markdown's defaults incl. Obsidian's
  '(("note" "󰋽 " "Note" md-render-info)
    ("tip" "󰌶 " "Tip" md-render-success)
    ("important" "󰅾 " "Important" md-render-hint)
    ("warning" "󰀪 " "Warning" md-render-warn)
    ("caution" "󰳦 " "Caution" md-render-error)
    ("abstract" "󰨸 " "Abstract" md-render-info)
    ("summary" "󰨸 " "Summary" md-render-info)
    ("tldr" "󰨸 " "Tldr" md-render-info)
    ("info" "󰋽 " "Info" md-render-info)
    ("todo" "󰗡 " "Todo" md-render-info)
    ("success" "󰄬 " "Success" md-render-success)
    ("check" "󰄬 " "Check" md-render-success)
    ("done" "󰄬 " "Done" md-render-success)
    ("question" "󰘥 " "Question" md-render-warn)
    ("help" "󰘥 " "Help" md-render-warn)
    ("faq" "󰘥 " "Faq" md-render-warn)
    ("failure" "󰅖 " "Failure" md-render-error)
    ("fail" "󰅖 " "Fail" md-render-error)
    ("missing" "󰅖 " "Missing" md-render-error)
    ("danger" "󱐌 " "Danger" md-render-error)
    ("error" "󱐌 " "Error" md-render-error)
    ("bug" "󰨰 " "Bug" md-render-error)
    ("example" "󰉹 " "Example" md-render-hint)
    ("quote" "󱆨 " "Quote" md-render-quote)
    ("cite" "󱆨 " "Cite" md-render-quote)))

;;;; Helpers

(defun md-render--show (beg end string)
  "Display STRING in place of BEG..END, even if markdown-mode hid it."
  (put-text-property beg end 'display string)
  (remove-text-properties beg end '(invisible nil)))

(defun md-render--in-code-p (pos)
  (save-excursion (goto-char pos) (markdown-code-block-at-point-p)))

(defun md-render--lang-icon (lang)
  (let* ((mode (intern-soft (concat lang "-mode")))
         (icon (and mode (ignore-errors (nerd-icons-icon-for-mode mode)))))
    (if (and (stringp icon) (not (equal icon (symbol-name mode))))
        icon
      (or (ignore-errors (nerd-icons-icon-for-extension lang))
          (nerd-icons-mdicon "nf-md-code_braces")))))

;;;; Renderers. Each is a font-lock matcher that does its work up to LAST and
;;;; returns nil, appended after markdown-mode's own keywords.

(defun md-render--headings (last)
  "`## Title' → icon right-aligned over the hashes, full-width band."
  (while (re-search-forward "^\\(#\\{1,6\\}\\)[ \t]+" last t)
    (let ((beg (match-beginning 0)) (end (match-end 0))
          (level (- (match-end 1) (match-beginning 1))))
      (when (and markdown-hide-markup (not (md-render--in-code-p beg)))
        (md-render--show beg end
                         (propertize (concat (make-string (max 0 (- end beg 2)) ?\s)
                                             (nth (1- level) md-render-heading-icons))
                                     'face (intern (format "markdown-header-face-%d" level))))
        (font-lock-append-text-property
         beg (min (point-max) (1+ (line-end-position))) 'face
         (intern (format "md-render-h%d" level))))))
  nil)

(defun md-render--fences (last)
  "Fences become code-background lines: the opening one shows the language's
icon and name, the closing one is empty. (markdown-mode would hide both
lines entirely, newline included.)"
  (while (re-search-forward "^[ \t]*\\(?:```\\|~~~\\)[ \t]*{?\\.?\\([[:alnum:]_+#-]*\\).*$" last t)
    (let ((beg (match-beginning 0)) (end (match-end 0))
          (lang (match-string-no-properties 1)))
      (when (and markdown-hide-markup
                 (or (get-text-property beg 'markdown-gfm-block-begin)
                     (get-text-property beg 'markdown-gfm-block-end)))
        (md-render--show beg end
                         (if (or (string-empty-p lang)
                                 (get-text-property beg 'markdown-gfm-block-end))
                             ""
                           (concat (md-render--lang-icon lang) " "
                                   (propertize lang 'face 'markdown-language-keyword-face))))
        (remove-text-properties end (min (point-max) (1+ end)) '(invisible nil)))))
  nil)

(defun md-render--hrs (last)
  "`---' → a rule across the window, like render-markdown."
  (while (re-search-forward markdown-regex-hr last t)
    (when (and markdown-hide-markup (not (md-render--in-code-p (match-beginning 0))))
      ;; a stretch to the window's right edge, struck through: follows resizes
      (md-render--show (match-beginning 0) (match-end 0) '(space :align-to right))
      (font-lock-prepend-text-property (match-beginning 0) (match-end 0)
                                       'face 'md-render-rule)))
  nil)

(defun md-render--checkboxes (last)
  "`- [ ] task' → `󰄱 task' (the list marker goes, like render-markdown)."
  (while (re-search-forward
          "^[ \t]*\\([-*+]\\|[0-9]+[.)]\\)[ \t]+\\(\\[\\([ xX-]\\)\\]\\)" last t)
    (when (and markdown-hide-markup (not (md-render--in-code-p (match-beginning 0))))
      (let ((state (match-string 3)))
        (md-render--show (match-beginning 1) (match-beginning 2) "")
        (md-render--show (match-beginning 2) (match-end 2)
                         (pcase state
                           (" " (propertize "󰄱" 'face 'md-render-unchecked))
                           ("-" (propertize "󰥔" 'face 'md-render-todo))
                           (_ (propertize "󰱒" 'face 'md-render-checked)))))))
  nil)

(defun md-render--callout-at (pos)
  "Callout entry for the blockquote containing POS, or nil."
  (save-excursion
    (goto-char pos)
    (beginning-of-line)
    (while (and (not (bobp))
                (save-excursion (forward-line -1) (looking-at-p "^[ \t]*>")))
      (forward-line -1))
    (when (looking-at "^[ \t]*>[ \t]*\\[!\\([[:alpha:]]+\\)\\]")
      (assoc (downcase (match-string 1)) md-render-callouts))))

(defun md-render--callouts (last)
  "`> [!NOTE]' → coloured icon and title, quote bars in the same colour."
  (while (re-search-forward "^[ \t]*\\(>\\)" last t)
    (let ((bar (match-beginning 1)))
      (when-let* ((markdown-hide-markup)
                  (callout (md-render--callout-at bar)))
        (pcase-let ((`(,_ ,icon ,title ,face) callout))
          (font-lock-prepend-text-property bar (1+ bar) 'face face)
          (when (looking-at "[ \t]*\\(\\[![[:alpha:]]+\\][+-]?\\)")
            (md-render--show (match-beginning 1) (match-end 1)
                             (propertize (concat icon title) 'face `(bold ,face))))))))
  nil)

(defun md-render--link-icon (url)
  (cond ((string-match-p "github\\.com" url) "󰊤 ")
        ((string-match-p "youtube\\.com\\|youtu\\.be" url) "󰗃 ")
        ((string-prefix-p "mailto:" url) "󰀓 ")
        (t "󰌹 ")))

(defun md-render--links (last)
  "Icon in front of links: `[text](url)' and `[[wiki]]'."
  (while (re-search-forward
          "\\(\\[\\[\\)[^]\n]+\\]\\]\\|\\(?:^\\|[^!]\\)\\(\\[\\)[^]\n]*\\](\\([^)\n]*\\))"
          last t)
    (when markdown-hide-markup
      (if (match-beginning 1)
          (md-render--show (match-beginning 1) (match-end 1)
                           (propertize "󱗖 " 'face 'markdown-link-face))
        (unless (md-render--in-code-p (match-beginning 2))
          (md-render--show (match-beginning 2) (match-end 2)
                           (propertize (md-render--link-icon (match-string 3))
                                       'face 'markdown-link-face))))))
  nil)

;;;; Tables: box-drawn borders, columns padded to line up

(defconst md-render--table-row "^[ \t]*|")
(defconst md-render--table-delim "^[ \t]*|?[ \t]*:?-+:?[ \t]*\\(|[ \t]*:?-+:?[ \t]*\\)*|?[ \t]*$")

(defun md-render--table-bounds ()
  "(BEG . END) of the table around point, END after its last newline."
  (save-excursion
    (beginning-of-line)
    (while (and (not (bobp))
                (save-excursion (forward-line -1) (looking-at-p md-render--table-row)))
      (forward-line -1))
    (let ((beg (point)) (end (point)))
      (while (looking-at-p md-render--table-row)
        (setq end (min (point-max) (1+ (line-end-position))))
        (forward-line 1))
      (cons beg end))))

(defun md-render--pipes ()
  "Positions of the unescaped, non-code `|' on the current line."
  (let (pipes (in-code nil))
    (save-excursion
      (beginning-of-line)
      (while (re-search-forward "\\\\.\\|`\\||" (line-end-position) t)
        (pcase (char-before)
          (?` (setq in-code (not in-code)))
          (?| (unless in-code (push (1- (point)) pipes))))))
    (nreverse pipes)))

(defun md-render--cell-width (text)
  "Rendered width of a cell's TEXT (markup hidden, link icons added)."
  (let ((s (string-trim text)))
    (setq s (replace-regexp-in-string "\\[\\[\\([^]|]*|\\)?\\([^]]*\\)\\]\\]" "xx\\2" s))
    (setq s (replace-regexp-in-string "!?\\[\\([^]]*\\)\\]([^)]*)" "xx\\1" s))
    (setq s (replace-regexp-in-string "\\*\\*\\|__\\|~~\\|`\\|\\\\\\(.\\)" "\\1" s))
    (string-width s)))

(defun md-render--table-layout (beg end)
  "Column widths and alignments of the table BEG..END, or nil if not a table."
  (save-excursion
    (goto-char beg)
    (forward-line 1)
    (when (looking-at-p md-render--table-delim)
      (let ((aligns (mapcar (lambda (c)
                              (let ((c (string-trim c)))
                                (cond ((and (string-prefix-p ":" c) (string-suffix-p ":" c)) 'center)
                                      ((string-suffix-p ":" c) 'right)
                                      (t 'left))))
                            (md-render--cells)))
            widths)
        (goto-char beg)
        (while (< (point) end)
          (unless (looking-at-p md-render--table-delim)
            (let ((i 0))
              (dolist (c (md-render--cells))
                (if (nth i widths)
                    (setf (nth i widths) (max (nth i widths) (md-render--cell-width c)))
                  (setq widths (append widths (list (md-render--cell-width c)))))
                (setq i (1+ i)))))
          (forward-line 1))
        (cons widths aligns)))))

(defun md-render--cells ()
  "Cell strings of the current table line."
  (let* ((pipes (md-render--pipes))
         (lbp (line-beginning-position)) (lep (line-end-position))
         (edges (append (if (and pipes (string-blank-p (buffer-substring lbp (car pipes))))
                            nil (list (1- lbp)))
                        pipes
                        (if (and pipes (string-blank-p (buffer-substring (1+ (car (last pipes))) lep)))
                            nil (list lep)))))
    (cl-loop for (a b) on edges while b
             collect (buffer-substring-no-properties (1+ a) b))))

(defun md-render--border (widths left mid right)
  (concat left (mapconcat (lambda (w) (make-string (+ w 2) ?─)) widths mid) right))

(defun md-render--table-row (widths aligns first last)
  "Render the table row at point."
  (let* ((pipes (md-render--pipes))
         (lbp (line-beginning-position)) (lep (line-end-position))
         (dim (lambda (s) (propertize s 'face 'md-render-dim))))
    (if (looking-at-p md-render--table-delim)
        (md-render--show lbp lep (funcall dim (md-render--border widths "├" "┼" "┤")))
      ;; Each pipe shows [right pad of the cell before] │ [left pad of the next];
      ;; whitespace around cell text is hidden so the pads are exact.
      (let ((col 0)
            (prev-pad nil))
        (dolist (p pipes)
          (let* ((next (or (cadr (memq p pipes)) lep))
                 (text-beg (save-excursion (goto-char (1+ p)) (skip-chars-forward " \t" next) (point)))
                 (text-end (save-excursion (goto-char next) (skip-chars-backward " \t" text-beg) (point)))
                 (lead "") (trail ""))
            (when (and (< (1+ p) next) (nth col widths) (cadr (memq p pipes)))
              (let* ((extra (- (nth col widths)
                               (md-render--cell-width (buffer-substring-no-properties text-beg text-end))))
                     (left (pcase (nth col aligns)
                             ('right extra) ('center (/ extra 2)) (_ 0))))
                (setq lead (make-string (1+ left) ?\s)
                      trail (make-string (1+ (- extra left)) ?\s))
                (md-render--show (1+ p) text-beg "")
                (md-render--show text-end next "")))
            (md-render--show p (1+ p)
                             (concat (or prev-pad "")
                                     (when (and first (eq p (car pipes)))
                                       (concat (funcall dim (md-render--border widths "┌" "┬" "┐")) "\n"))
                                     (funcall dim "│")
                                     (when (and last (eq p (car (last pipes))))
                                       (concat "\n" (funcall dim (md-render--border widths "└" "┴" "┘"))))
                                     lead))
            (setq prev-pad trail
                  col (1+ col))))))))

(defun md-render--tables (last)
  (while (re-search-forward md-render--table-row last t)
    (let* ((bounds (md-render--table-bounds))
           (layout (and markdown-hide-markup
                        (not (md-render--in-code-p (point)))
                        (md-render--table-layout (car bounds) (cdr bounds)))))
      (when layout
        (save-excursion
          (goto-char (car bounds))
          (while (< (point) (cdr bounds))
            (md-render--table-row (car layout) (cdr layout)
                                  (= (point) (car bounds))
                                  (>= (1+ (line-end-position)) (cdr bounds)))
            (forward-line 1))))
      (goto-char (max (point) (min last (cdr bounds))))))
  nil)

(defun md-render--extend-to-tables ()
  "Fontify whole tables, since every row's padding depends on the others."
  (let ((changed nil))
    (save-excursion
      (goto-char font-lock-beg)
      (when (looking-at-p md-render--table-row)
        (let ((b (car (md-render--table-bounds))))
          (when (< b font-lock-beg) (setq font-lock-beg b changed t))))
      (goto-char font-lock-end)
      (when (and (bolp) (not (bobp))) (forward-line -1))
      (when (looking-at-p md-render--table-row)
        (let ((e (cdr (md-render--table-bounds))))
          (when (> e font-lock-end) (setq font-lock-end e changed t)))))
    changed))

(defconst md-render--keywords
  '((md-render--headings) (md-render--fences) (md-render--hrs) (md-render--checkboxes)
    (md-render--callouts) (md-render--links) (md-render--tables)))

;;;; Source range

(defvar-local md-render--raw nil
  "(BEG . END) shown as source, or nil.")
(defvar-local md-render--stashed nil
  "Math and image overlays currently shown as source.")
(defvar-local md-render--goal nil
  "Character column `j'/`k' keep, like Vim's.")
(defvar-local md-render--goal-pos nil
  "Where the last `j'/`k' left point.")

(defun md-render--wanted-raw ()
  (cond ((memq evil-state '(insert replace emacs))
         (cons (point-min) most-positive-fixnum)) ; stable while typing
        ((evil-visual-state-p)
         (cons (save-excursion (goto-char evil-visual-beginning) (line-beginning-position))
               (save-excursion (goto-char (max evil-visual-beginning (1- evil-visual-end)))
                               (1+ (line-end-position)))))
        (t (cons (line-beginning-position) (1+ (line-end-position))))))

(defun md-render--fontify-region (beg end &optional loudly)
  "`font-lock-fontify-region-function' that leaves `md-render--raw' as source."
  (let* ((bounds (font-lock-default-fontify-region beg end loudly))
         ;; font-lock may have widened BEG..END (whole code blocks, tables)
         (beg (or (cadr bounds) beg))
         (end (or (cddr bounds) end))
         (raw md-render--raw))
    (when (and raw (< (car raw) end) (> (cdr raw) beg))
      ;; Redo the source lines without hiding. Only whole-line widening here,
      ;; so the source range doesn't spread to the whole paragraph or block.
      (let ((rb (max beg (car raw)))
            (re (min end (cdr raw)))
            (markdown-hide-markup nil)
            (font-lock-extend-region-functions '(font-lock-extend-region-wholelines)))
        (font-lock-default-fontify-region rb re loudly)
        (with-silent-modifications
          (remove-text-properties rb re '(invisible nil)))))
    `(jit-lock-bounds ,beg . ,end)))

(defun md-render--sync-overlays ()
  "Show math/image overlays as source inside the raw range, rendered elsewhere."
  (dolist (ov md-render--stashed)
    (when (overlay-buffer ov)
      (overlay-put ov 'display (overlay-get ov 'md-render-display))
      (overlay-put ov 'face (overlay-get ov 'md-render-face))))
  (setq md-render--stashed nil)
  (when md-render--raw
    (dolist (ov (overlays-in (car md-render--raw) (min (cdr md-render--raw) (point-max))))
      (when (or (eq (overlay-get ov 'category) 'math-preview)
                (memq ov markdown-inline-image-overlays))
        (overlay-put ov 'md-render-display (overlay-get ov 'display))
        (overlay-put ov 'md-render-face (overlay-get ov 'face))
        (overlay-put ov 'display nil)
        (overlay-put ov 'face nil)
        (push ov md-render--stashed)))))

(defun md-render--post-command ()
  ;; Emacs would otherwise push point out of the hidden text it lands in,
  ;; before that line has been redrawn as source.
  (setq disable-point-adjustment t)
  (let ((old md-render--raw)
        (new (md-render--wanted-raw)))
    (unless (equal old new)
      (setq md-render--raw new)
      (dolist (r (list old new))
        (when r (font-lock-flush (min (car r) (point-max)) (min (cdr r) (point-max)))))
      ;; Redraw the new source lines right away (not at redisplay), so point
      ;; never sees them rendered. Skipped before font-lock is on.
      (when (and jit-lock-functions (not (eq (cdr new) most-positive-fixnum)))
        (jit-lock-fontify-now (car new) (min (cdr new) (point-max))))
      (md-render--sync-overlays))))

(defun md-render--line-move (orig arg &rest args)
  "Keep the character column on `j'/`k' like Vim, not the on-screen column.
The line moved to is still rendered while the move is computed, so screen
columns would land on the wrong character once it turns into source."
  (if (or (not my/markdown-render-mode) line-move-visual (zerop arg)
          ;; only evil's j/k (`evil-line-move' sets this-command), not other
          ;; callers of `line-move' such as `$'
          (not (memq this-command '(next-line previous-line))))
      (apply orig arg args)
    ;; Keep the goal while j/k repeat (point still where the last one left
    ;; it, or one back where evil keeps it off the newline); otherwise take
    ;; it from point. `$' sets the goal to "line end".
    (unless (and md-render--goal md-render--goal-pos
                 (memq last-command '(next-line previous-line))
                 (<= (1- md-render--goal-pos) (point) md-render--goal-pos))
      (setq md-render--goal
            (if (and (eq temporary-goal-column most-positive-fixnum)
                     (>= (point) (1- (line-end-position))))
                most-positive-fixnum
              (- (point) (line-beginning-position)))))
    (let ((dir (if (< arg 0) -1 1)) (moved 0) (noerror (car args)))
      (while (and (< moved (abs arg))
                  (if (> dir 0)
                      (< (line-end-position) (point-max))
                    (> (line-beginning-position) (point-min))))
        (forward-line dir)
        (setq moved (1+ moved)))
      (goto-char (min (+ (line-beginning-position) md-render--goal) (line-end-position)))
      (setq md-render--goal-pos (point))
      (when (and (zerop moved) (not noerror))
        (signal (if (> dir 0) 'end-of-buffer 'beginning-of-buffer) nil)))))

(advice-add 'line-move :around #'md-render--line-move)

(defun md-render--math ()
  (math-preview-all)
  (md-render--sync-overlays))

;;;###autoload
(define-minor-mode my/markdown-render-mode
  "Render markdown in place like render-markdown.nvim, with images and math."
  :lighter nil
  (if my/markdown-render-mode
      (progn
        (setq-local font-lock-fontify-region-function #'md-render--fontify-region)
        (font-lock-add-keywords nil md-render--keywords 'append)
        (add-hook 'font-lock-extend-region-functions #'md-render--extend-to-tables nil t)
        (setq-local markdown-hide-markup nil)
        (markdown-toggle-markup-hiding 1) ; also refontifies the buffer
        (add-hook 'post-command-hook #'md-render--post-command nil t)
        ;; images and SVG math need a GUI frame; `emacs -nw' just hides markup
        (when (display-graphic-p)
          (markdown-display-inline-images)
          (when (executable-find "math-preview")
            (math-preview-all)
            (add-hook 'after-save-hook #'md-render--math nil t)))
        (md-render--post-command))
    (remove-hook 'post-command-hook #'md-render--post-command t)
    (remove-hook 'after-save-hook #'md-render--math t)
    (remove-hook 'font-lock-extend-region-functions #'md-render--extend-to-tables t)
    (font-lock-remove-keywords nil md-render--keywords)
    (setq md-render--raw nil)
    (md-render--sync-overlays)
    (kill-local-variable 'font-lock-fontify-region-function)
    (markdown-toggle-markup-hiding -1)
    (when (display-graphic-p)
      (markdown-remove-inline-images)
      (math-preview-clear-all))))

(provide 'md-render)
;;; md-render.el ends here
