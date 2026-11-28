;;; init-folding.el --- built-in folding -*- lexical-binding: t; -*-

;; Two built-in engines cover the workflows this configuration needs:
;; hideshow for brace and comment blocks, outline for heading-like
;; structure (Emacs Lisp ;;;, Markdown headings, Org, and the modes that
;; set `outline-regexp'). Neither is turned on globally: a fold command
;; enables the engine it needs in the current buffer only, so opening a
;; buffer never pays for folding it does not use.

(defun my/ensure-hideshow ()
  "Turn on `hs-minor-mode' in this buffer when it is not already on."
  (unless (bound-and-true-p hs-minor-mode)
    (require 'hideshow)
    (setq hs-hide-comments-when-hiding-all t
          hs-isearch-open t)
    (hs-minor-mode 1)))

(defun my/toggle-fold ()
  "Toggle the fold at point: hideshow block first, outline heading second."
  (interactive)
  (cond
   ((bound-and-true-p hs-minor-mode)
    (condition-case nil
        (hs-toggle-hiding)
      (error (user-error "No fold here"))))
   ((bound-and-true-p outline-minor-mode)
    (condition-case nil
        (outline-toggle-children)
      (error (user-error "No fold here"))))
   (t
    (condition-case nil
        (progn (my/ensure-hideshow) (hs-toggle-hiding))
      (error
       (condition-case nil
           (progn (outline-minor-mode 1) (outline-toggle-children))
         (error (user-error "No fold here"))))))))

(defun my/hide-all ()
  "Hide every fold in the buffer."
  (interactive)
  (condition-case nil
      (progn (my/ensure-hideshow) (hs-hide-all))
    (error
     (when (bound-and-true-p outline-minor-mode) (outline-hide-body)))))

(defun my/show-all ()
  "Show every fold in the buffer."
  (interactive)
  (condition-case nil
      (progn (my/ensure-hideshow) (hs-show-all))
    (error
     (when (bound-and-true-p outline-minor-mode) (outline-show-all)))))

(defun my/toggle-comment-fold ()
  "Toggle the comment block at point."
  (interactive)
  (cond
   ((bound-and-true-p hs-minor-mode)
    (condition-case nil
        (hs-toggle-hiding)
      (error (user-error "No comment fold here"))))
   ((bound-and-true-p outline-minor-mode)
    (condition-case nil
        (outline-toggle-children)
      (error (user-error "No comment fold here"))))
   (t
    (condition-case nil
        (progn (my/ensure-hideshow) (hs-toggle-hiding))
      (error
       (condition-case nil
           (progn (outline-minor-mode 1) (outline-toggle-children))
         (error (user-error "No comment fold here"))))))))

(defun my/toggle-top-level ()
  "Fold the buffer to its top-level sections."
  (interactive)
  (if (bound-and-true-p outline-minor-mode)
      (outline-hide-sublevels 1)
    (condition-case nil
        (progn (my/ensure-hideshow) (hs-hide-all))
      (error
       (outline-minor-mode 1)
       (outline-hide-sublevels 1)))))

(defun my/hide-levels (level)
  "Hide all sections deeper than LEVEL."
  (interactive "p")
  (unless (bound-and-true-p outline-minor-mode)
    (outline-minor-mode 1))
  (outline-hide-sublevels (max 1 (or level 1))))

(defun my/toggle-outline ()
  "Toggle the outline heading at point."
  (interactive)
  (unless (bound-and-true-p outline-minor-mode)
    (outline-minor-mode 1))
  (outline-toggle-children))

;; One prefix for every fold command: `f' toggle, `h'/`s' hide/show
;; all, `c' comment fold, `t' top level, `l' hide levels, `o' outline.
(defvar-keymap my/fold-map
  "f" #'my/toggle-fold
  "h" #'my/hide-all
  "s" #'my/show-all
  "c" #'my/toggle-comment-fold
  "t" #'my/toggle-top-level
  "l" #'my/hide-levels
  "o" #'my/toggle-outline)

(provide 'init-folding)
;;; init-folding.el ends here
