;;; init-navigation.el --- definitions, buffers and tree-sitter motion -*- lexical-binding: t; -*-

;; xref is the built-in jump-to-definition engine: `M-.' and `M-,' are
;; already bound, so this file only adds the rest of the workflow under
;; one discoverable prefix, `C-c t'. Everything here is a built-in
;; command or a thin wrapper that falls back to the non-tree-sitter
;; equivalent when the current buffer has no parser.

(require 'cl-lib)

;; Imenu indexes definitions from the mode's own imenu expression; it is
;; the cheap "go to a symbol in this file" path that works everywhere.
(setq imenu-auto-rescan t
      imenu-auto-rescan-maxout 600000)

(defun my/alternate-buffer ()
  "Switch to the most recent other buffer in this window."
  (interactive)
  (switch-to-buffer (other-buffer (current-buffer) t)))

(defun my/treesit-buffer-p ()
  "Non-nil when the current buffer has an active tree-sitter parser."
  (and (fboundp 'treesit-available-p)
       (treesit-available-p)
       (bound-and-true-p treesit-parser-list)
       (not (null treesit-parser-list))))

(defun my/treesit-forward-sexp (&optional arg)
  "Move forward ARG tree-sitter sexps, or `forward-sexp' without a parser."
  (interactive "p")
  (condition-case nil
      (if (my/treesit-buffer-p)
          (treesit-forward-sexp arg)
        (forward-sexp arg))
    (error (forward-sexp arg))))

(defun my/treesit-backward-sexp (&optional arg)
  "Move backward ARG tree-sitter sexps."
  (interactive "p")
  (my/treesit-forward-sexp (- (or arg 1))))

(defun my/treesit-beginning-of-defun (&optional arg)
  "Move to the beginning of the ARGth defun."
  (interactive "p")
  (condition-case nil
      (if (my/treesit-buffer-p)
          (treesit-beginning-of-defun arg)
        (beginning-of-defun arg))
    (error (beginning-of-defun arg))))

(defun my/treesit-end-of-defun (&optional arg)
  "Move to the end of the ARGth defun."
  (interactive "p")
  (condition-case nil
      (if (my/treesit-buffer-p)
          (treesit-end-of-defun arg)
        (end-of-defun arg))
    (error (end-of-defun arg))))

(defun my/treesit-next-defun (&optional arg)
  "Move forward ARG defuns, tree-sitter first, `beginning-of-defun' second."
  (interactive "p")
  (my/treesit-beginning-of-defun (- (or arg 1))))

(defun my/treesit-prev-defun (&optional arg)
  "Move backward ARG defuns."
  (interactive "p")
  (my/treesit-beginning-of-defun (or arg 1)))

(defun my/treesit-up-list (&optional arg)
  "Move upward ARG lists; use tree-sitter when Emacs 31 provides it."
  (interactive "p")
  (if (fboundp 'treesit-up-list)
      (treesit-up-list arg)
    (up-list arg)))

(defun my/treesit-down-list (&optional arg)
  "Move downward ARG lists; use tree-sitter when Emacs 31 provides it."
  (interactive "p")
  (if (fboundp 'treesit-down-list)
      (treesit-down-list arg)
    (down-list arg)))

(defun my/treesit-inspect ()
  "Toggle `treesit-inspect-mode' when this Emacs has it."
  (interactive)
  (if (fboundp 'treesit-inspect-mode)
      (treesit-inspect-mode 'toggle)
    (user-error "This Emacs has no tree-sitter inspect mode")))

(defun my/treesit-explore ()
  "Toggle `treesit-explore-mode' when this Emacs has it."
  (interactive)
  (if (fboundp 'treesit-explore-mode)
      (treesit-explore-mode 'toggle)
    (user-error "This Emacs has no tree-sitter explore mode")))

;; One prefix for structural navigation. `n'/`p' cycle through defuns,
;; `f'/`b' move by sexp, `u'/`d' change list depth, `a'/`e' jump to the
;; defun edges, and `i'/`x' open the tree-sitter inspector/explorer.
(defvar-keymap my/nav-map
  "n" #'my/treesit-next-defun
  "p" #'my/treesit-prev-defun
  "f" #'my/treesit-forward-sexp
  "b" #'my/treesit-backward-sexp
  "u" #'my/treesit-up-list
  "d" #'my/treesit-down-list
  "a" #'my/treesit-beginning-of-defun
  "e" #'my/treesit-end-of-defun
  "i" #'my/treesit-inspect
  "x" #'my/treesit-explore)

(provide 'init-navigation)
;;; init-navigation.el ends here
