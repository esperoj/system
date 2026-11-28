;;; init-keybindings.el --- global keybindings -*- lexical-binding: t; -*-

;; Global bindings live here so every binding can be found beside the
;; command it names. Major-mode maps still win locally: this file never
;; overrides a mode's own keys, which is why the navigation and folding
;; prefixes are two-key sequences (`C-c t', `C-c f') rather than single
;; keys that modes commonly use.

(keymap-global-set "C-x g" #'my/magit-status)
(keymap-global-set "C-x C-r" #'my/recentf-open)

;; `M-/' was comment-line, which hid the built-in hippie-expand
;; completion. Comments move to `C-;' and `C-c C-;'.
(keymap-global-set "M-/" #'hippie-expand)
(keymap-global-set "C-;" #'comment-line)
(keymap-global-set "C-c C-;" #'comment-or-uncomment-region)

;; Buffer and definition workflow.
(keymap-global-set "C-c b" #'my/alternate-buffer)
(keymap-global-set "C-c i" #'imenu)
(keymap-global-set "C-c C-<left>" #'winner-undo)
(keymap-global-set "C-c C-<right>" #'winner-redo)

;; Structural navigation (`C-c t') and folding (`C-c f').
(keymap-global-set "C-c t" my/nav-map)
(keymap-global-set "C-c f" my/fold-map)

;; Whole-buffer editing helpers.
(keymap-global-set "C-c C-=" #'my/format-buffer)
(keymap-global-set "C-c C-\\" #'my/indent-buffer)

(provide 'init-keybindings)
;;; init-keybindings.el ends here
