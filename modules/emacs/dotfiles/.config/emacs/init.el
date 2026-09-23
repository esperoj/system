;;; init.el --- Sovereign, Portable IDE for Perma Projects -*- lexical-binding: t; -*-

;;; Commentary:
;; Philosophy: Built-ins first. Minimal external dependencies. Emacs 29+.
;; Storage: Strict XDG compliance. Code in config, generated state elsewhere.
;; Ergonomics: Frictionless daily editing and coding using modern Emacs features.
;; Workflows: OCaml (ocamllsp), Python (pyright), Bash, JSON, YAML, TOML, Markdown, and Git (Magit).

;;; Code:

;; Forward declarations to silence byte-compiler warnings
(defvar tramp-persistency-file-name)
(defvar url-configuration-directory)
(defvar treesit-language-source-alist)
(defvar major-mode-remap-alist)
(defvar icomplete-show-matches-on-no-input)
(defvar icomplete-hide-common-prefix)
(defvar savehist-file)
(defvar markdown-command)

;; ===========================================================================
;; 0. XDG & ENVIRONMENT (NO LITTERING)
;; ===========================================================================
(defconst xdg-state-home (or (getenv "XDG_STATE_HOME") "~/.local/state"))
(defconst xdg-cache-home (or (getenv "XDG_CACHE_HOME") "~/.cache"))
(defconst xdg-data-home  (or (getenv "XDG_DATA_HOME")  "~/.local/share"))

(defconst my/state-dir (expand-file-name "emacs/" xdg-state-home))
(defconst my/cache-dir (expand-file-name "emacs/" xdg-cache-home))
(defconst my/data-dir  (expand-file-name "emacs/" xdg-data-home))

;; Create all necessary state directories in one pass
(dolist (dir (list my/state-dir my/cache-dir my/data-dir
                   (expand-file-name "backups" my/state-dir)
                   (expand-file-name "auto-save" my/state-dir)))
  (make-directory dir t))

;; Strict XDG paths for built-in variables
(setq user-emacs-directory my/state-dir
      package-user-dir (expand-file-name "elpa" my/state-dir)
      backup-directory-alist `(("." . ,(expand-file-name "backups" my/state-dir)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save" my/state-dir) t))
      create-lockfiles nil
      custom-file (expand-file-name "custom.el" my/state-dir)
      tramp-persistency-file-name (expand-file-name "tramp" my/cache-dir)
      url-configuration-directory (expand-file-name "url/" my/cache-dir))

(when (boundp 'native-comp-eln-load-path)
  (add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" my/cache-dir)))

(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; ===========================================================================
;; 1. STARTUP PERFORMANCE & UI CLEANUP
;; ===========================================================================
(setq gc-cons-threshold 100000000
      inhibit-startup-screen t
      inhibit-startup-message t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

(add-hook 'emacs-startup-hook (lambda () (setq gc-cons-threshold 800000)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; ===========================================================================
;; 2. MODERN ERGONOMICS (BUILT-IN QOL)
;; ===========================================================================
(pixel-scroll-precision-mode 1) ;; Smooth scrolling (Emacs 29+)
(global-auto-revert-mode 1)     ;; Auto-reload files changed on disk
(save-place-mode 1)             ;; Remember cursor position in files
(savehist-mode 1)               ;; Persist minibuffer history
(winner-mode 1)                 ;; Undo/redo window layouts (C-c <left>/<right>)
(electric-pair-mode 1)          ;; Auto-close brackets and quotes
(delete-selection-mode 1)       ;; Type over selected text
(repeat-mode 1)                 ;; Repeat commands without modifier keys
(setq-default indent-tabs-mode nil) ;; Spaces over tabs

;; ===========================================================================
;; 3. PACKAGE MANAGEMENT (APT + ELPA DUAL SUPPORT)
;; ===========================================================================
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

(defun my/ensure-packages (pkgs)
  "Ensure PKGS are available.
Checks both ELPA package list and system-provided packages (apt)."
  (let ((to-install nil))
    (dolist (pkg pkgs)
      (unless (or (package-installed-p pkg)
                  (require pkg nil 'noerror))
        (push pkg to-install)))
    (when to-install
      (unless package-archive-contents
        (package-refresh-contents))
      (dolist (pkg to-install)
        (package-install pkg)))))

;; Ensure external packages exist (installed via apt or downloaded via ELPA)
(my/ensure-packages '(magit markdown-mode tuareg yaml-mode treesit-auto))

;; ===========================================================================
;; 4. COMPLETION & MINIBUFFER (ICOMPLETE + FLEX)
;; ===========================================================================
(icomplete-vertical-mode 1)
(setq icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil)

(setq completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic))))

(setq completions-detailed t
      completions-format 'one-column
      completions-max-height 15
      completion-cycle-threshold 3
      tab-always-indent 'complete
      completion-auto-select 'second-tab)

(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; ===========================================================================
;; 5. RECENT FILES & PROJECT MANAGEMENT
;; ===========================================================================
(require 'recentf)
(setq recentf-save-file (expand-file-name "recentf" my/state-dir)
      recentf-max-saved-items 200)
(recentf-mode 1)

(setq savehist-file (expand-file-name "history" my/state-dir))
(savehist-mode 1)

(require 'project)
(setq project-list-file (expand-file-name "projects" my/state-dir))

;; ===========================================================================
;; 6. VERSION CONTROL (GIT & MAGIT)
;; ===========================================================================
(with-eval-after-load 'magit
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; Enable smerge-mode hook for inline conflict resolution
(add-hook 'find-file-hook
          (lambda ()
            (when (and buffer-file-name
                       (save-excursion
                         (goto-char (point-min))
                         (re-search-forward "^<<<<<<< " nil t)))
              (smerge-mode 1))))

;; ===========================================================================
;; 7. TREE-SITTER & FILE ASSOCIATIONS
;; ===========================================================================
;; Manual fallback recipes for tree-sitter grammars
(defconst my/treesit-languages
  '((bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.20.0")
    (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
    (json "https://github.com/tree-sitter/tree-sitter-json" "v0.20.2")
    (ocaml "https://github.com/tree-sitter/tree-sitter-ocaml" "master" "grammars/ocaml")
    (yaml "https://github.com/ikatyang/tree-sitter-yaml")
    (toml "https://github.com/tree-sitter/tree-sitter-toml" "v0.20.0")))

(defun my/has-c-compiler-p ()
  "Return non-nil if a C compiler is available for tree-sitter."
  (or (executable-find "cc") (executable-find "gcc") (executable-find "clang")))

(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (if (require 'treesit-auto nil 'noerror)
      (global-treesit-auto-mode 1)
    (progn
      (setq treesit-language-source-alist my/treesit-languages)
      (if (my/has-c-compiler-p)
          (dolist (lang my/treesit-languages)
            (unless (treesit-language-available-p (car lang))
              (condition-case err
                  (treesit-install-language-grammar (car lang))
                (error (message "Tree-sitter compile error for %s: %s"
                                (car lang) (error-message-string err))))))
        (message "No C compiler found. Skipping Tree-sitter auto-compilation."))
      
      ;; Manual mode mappings fallback
      (defconst my/ts-mode-mappings
        '((bash . sh-mode)
          (python . python-mode)
          (json . js-json-mode)
          (ocaml . tuareg-mode)
          (yaml . yaml-mode)
          (toml . conf-toml-mode)))

      (dolist (mapping my/ts-mode-mappings)
        (let ((lang (car mapping))
              (fallback-mode (cdr mapping)))
          (when (treesit-language-available-p lang)
            (add-to-list 'major-mode-remap-alist
                         (cons fallback-mode (intern (format "%s-ts-mode" lang))))))))))

;; Explicit non-TS mode associations
(add-to-list 'auto-mode-alist '("\\.yaml\\|\\.yml\\'" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.toml\\'" . conf-toml-mode))

;; ===========================================================================
;; 8. LANGUAGE WORKFLOWS (OCAML, PYTHON, BASH, JSON, YAML, MARKDOWN)
;; ===========================================================================
(require 'eglot)
(add-to-list 'warning-suppress-types '(eglot))

;; --- OCAML WORKFLOW ---
(require 'tuareg nil 'noerror)
(add-to-list 'auto-mode-alist '("\\.ml[iip]?\\'" . tuareg-mode))

(defun my/setup-opam-env ()
  "Dynamically import OPAM binary paths and site-lisp into Emacs environment."
  (when-let* ((opam-bin (executable-find "opam"))
              (bin-dir (ignore-errors (car (process-lines opam-bin "var" "bin"))))
              (share-dir (ignore-errors (car (process-lines opam-bin "var" "share")))))
    (when (file-directory-p bin-dir)
      (add-to-list 'exec-path bin-dir)
      (setenv "PATH" (concat bin-dir path-separator (getenv "PATH"))))
    (when (file-directory-p share-dir)
      (let ((opam-lisp (expand-file-name "emacs/site-lisp" share-dir)))
        (when (file-directory-p opam-lisp)
          (add-to-list 'load-path opam-lisp)
          (require 'ocp-indent nil t))))))

(my/setup-opam-env)

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((tuareg-mode ocaml-ts-mode caml-mode) . ("ocamllsp"))))

(add-hook 'tuareg-mode-hook #'eglot-ensure)
(when (fboundp 'ocaml-ts-mode)
  (add-hook 'ocaml-ts-mode-hook #'eglot-ensure))

;; --- PYTHON WORKFLOW ---
(defun my/python-activate-venv ()
  "Locate and activate a venv or .venv in the current project root."
  (let ((root (if-let ((proj (project-current))) (project-root proj) default-directory)))
    (when-let ((venv-dir (car (directory-files root t "^\\.?venv$" t)))
               (bin-dir (expand-file-name "bin" venv-dir))
               (python-bin (expand-file-name "python" bin-dir)))
      (when (file-executable-p python-bin)
        (setenv "VIRTUAL_ENV" venv-dir)
        (setq-local exec-path (cons bin-dir exec-path))
        (setenv "PATH" (concat bin-dir path-separator (getenv "PATH")))
        (message "Activated venv: %s" venv-dir)))))

(add-hook 'python-base-mode-hook #'eglot-ensure)
(add-hook 'python-base-mode-hook #'my/python-activate-venv)

;; --- BASH, JSON, YAML WORKFLOWS ---
(setq js-indent-level 2)
(dolist (hook '(bash-ts-mode-hook sh-mode-hook
                json-ts-mode-hook js-json-mode-hook
                yaml-ts-mode-hook yaml-mode-hook))
  (add-hook hook #'eglot-ensure))

;; --- MARKDOWN WORKFLOW ---
;; Unconditionally associate Markdown file extensions.
;; Emacs will trigger package autoloads dynamically when the file is opened.
(setq markdown-command "pandoc -f markdown -t html --standalone"
      markdown-header-scaling t)

(add-to-list 'auto-mode-alist '("\\.\\(?:md\\Vert{}markdown\\)\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))
(add-hook 'markdown-mode-hook #'visual-line-mode)

;; ===========================================================================
;; 9. VISUALS & TYPOGRAPHY
;; ===========================================================================
(load-theme 'modus-vivendi t)
(set-face-attribute 'default nil :font "Monospace" :height 140)
(setq-default line-spacing 0.15)

(column-number-mode 1)
(global-display-line-numbers-mode 1)

;; ===========================================================================
;; 10. KEYBINDINGS & NAVIGATION
;; ===========================================================================
(keymap-global-set "C-x g"   #'magit-status)       ;; Canonical Git status dashboard
(keymap-global-set "C-c r"   #'recentf-open-files) ;; Fast recent file switcher
(keymap-global-set "C-x C-b" #'ibuffer)            ;; Modern buffer list
(keymap-global-set "M-o"     #'other-window)       ;; Fast window switching
(keymap-global-set "C-c p p" #'project-switch-project)
(keymap-global-set "C-c p f" #'project-find-file)

;; --- CODE OUTLINE (Like Zed/VSCode) ---
;; `imenu` reads the current Tree-sitter or Eglot (LSP) tree and builds a searchable TOC.
(keymap-global-set "C-c o"   #'imenu)

(provide 'init)
;;; init.el ends here
