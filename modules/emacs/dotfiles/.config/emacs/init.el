;;; init.el --- Fast, Smooth & Ergonomic IDE -*- lexical-binding: t; -*-

;; This file is only the entry point. The configuration lives in one
;; feature per file under lisp/, so a change to completion does not
;; touch the UI, and a missing optional package cannot break boot.
;;
;; Loading order is the only policy here: core first (paths, state,
;; defaults), then editing, completion, navigation, folding, UI, git,
;; languages, packages, mobile, and keybindings last so every command
;; it binds is defined.

(defvar my/init-directory
  (file-name-directory (or load-file-name buffer-file-name))
  "Directory containing init.el, the root of this configuration.")

(add-to-list 'load-path (expand-file-name "lisp" my/init-directory))

(require 'init-core)
(require 'init-editing)
(require 'init-completion)
(require 'init-navigation)
(require 'init-folding)
(require 'init-ui)
(require 'init-git)
(require 'init-lang)
(require 'init-packages)
(require 'init-mobile)
(require 'init-keybindings)

(provide 'init)
;;; init.el ends here
