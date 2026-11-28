;;; init-completion.el --- minibuffer and in-buffer completion -*- lexical-binding: t; -*-

;; Fast built-in completion, no external framework. The minibuffer uses
;; icomplete-vertical with the cheap completion styles first and flex
;; last; in-buffer completion goes through `completion-at-point' (which
;; Eglot and the major modes extend) with `hippie-expand' as the
;; always-available fallback for prose and non-LSP buffers.

(setq tab-always-indent 'complete
      completions-detailed t
      completion-auto-select t
      completions-max-height 12
      icomplete-compute-delay 0.1
      icomplete-show-matches-on-no-input t
      completion-ignore-case t
      read-buffer-completion-ignore-case t
      read-file-name-completion-ignore-case t)

;; Emacs 30.1; setting it on an older Emacs is harmless but pointless.
(when (boundp 'completions-sort)
  (setq completions-sort 'historical))

;; Order styles: fast prefixes first, heavy fuzzy matching last.
(setq completion-styles '(basic substring partial-completion flex)
      completion-category-defaults nil
      completion-category-overrides
      '((file (styles basic substring partial-completion))
        (buffer (styles basic substring partial-completion))))

(icomplete-vertical-mode 1)
(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; hippie-expand is the one-completion-command workflow: files,
;; dabbrev across buffers, abbrevs, lists and lines. `M-/' used to be
;; comment-line, which hid this built-in; comment-line now lives on
;; `C-;'.
(setq hippie-expand-try-functions-list
      '(try-complete-file-name-partially
        try-complete-file-name
        try-expand-dabbrev
        try-expand-dabbrev-all-buffers
        try-expand-dabbrev-from-kill
        try-expand-all-abbrevs
        try-expand-list
        try-expand-line)
      dabbrev-case-fold-search nil)

(provide 'init-completion)
;;; init-completion.el ends here
