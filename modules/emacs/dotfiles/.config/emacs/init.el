;;; init.el --- Sovereign, Portable IDE for Perma Projects -*- lexical-binding: t; -*-

;;; Commentary:
;; Philosophy: Built-ins first.  Minimal external dependencies.  Emacs 29+.
;; Storage: Strict XDG compliance.  Code in config, generated files elsewhere.
;; Ergonomics: Frictionless daily editing and coding using modern Emacs features.
;; Architecture: Organized by domain for easy understanding and future updates.

;;; Code:

;; Forward declarations to silence byte-compiler warnings
(defvar tramp-persistency-file-name)
(defvar url-configuration-directory)
(defvar treesit-language-source-alist)
(defvar major-mode-remap-alist)
(defvar icomplete-show-matches-on-no-input)
(defvar icomplete-hide-common-prefix)
(defvar savehist-file)

;; ===========================================================================
;; 0. XDG & ENVIRONMENT (NO LITTERING)
;; ===========================================================================
(defconst xdg-state-home (or (getenv "XDG_STATE_HOME") "~/.local/state"))
(defconst xdg-cache-home (or (getenv "XDG_CACHE_HOME") "~/.cache"))
(defconst xdg-data-home  (or (getenv "XDG_DATA_HOME")  "~/.local/share"))

(defconst my/state-dir (expand-file-name "emacs/" xdg-state-home))
(defconst my/cache-dir (expand-file-name "emacs/" xdg-cache-home))
(defconst my/data-dir  (expand-file-name "emacs/" xdg-data-home))

;; Create all necessary directories in one pass
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
      ring-bell-function 'ignore) ;; Silent bell for less distraction

(add-hook 'emacs-startup-hook (lambda () (setq gc-cons-threshold 800000)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; ===========================================================================
;; 2. MODERN ERGONOMICS (BUILT-IN QOL)
;; ===========================================================================
;; These built-in minor modes drastically improve daily editing friction.
(pixel-scroll-precision-mode 1) ;; Smooth, precise scrolling (Emacs 29+)
(global-auto-revert-mode 1)     ;; Auto-reload files changed on disk
(save-place-mode 1)             ;; Remember cursor position in files
(savehist-mode 1)               ;; Persist minibuffer history (M-p / M-n)
(winner-mode 1)                 ;; Undo/redo window layouts (C-c <left>/<right>)
(electric-pair-mode 1)          ;; Auto-close brackets and quotes
(delete-selection-mode 1)       ;; Type over selected text
(repeat-mode 1)                 ;; Repeat commands without modifier keys
(setq-default indent-tabs-mode nil) ;; Spaces > Tabs for consistency

;; ===========================================================================
;; 3. EXTERNAL PACKAGES (MINIMAL)
;; ===========================================================================
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))
(package-initialize)

(let ((pkgs '(vc-fossil markdown-mode)))
  (unless (seq-every-p #'package-installed-p pkgs)
    (package-refresh-contents)
    (mapc #'package-install pkgs)))

(with-eval-after-load 'vc
  (add-to-list 'vc-handled-backends 'Fossil))

;; ===========================================================================
;; 4. COMPLETION & MINIBUFFER (ICOMPLETE + FLEX)
;; ===========================================================================
(icomplete-vertical-mode 1)
(setq icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil)

;; Smart fuzzy/substring matching
(setq completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic))))

;; In-buffer code completion settings
(setq completions-detailed t
      completions-format 'one-column
      completions-max-height 15
      completion-cycle-threshold 3
      tab-always-indent 'complete
      completion-auto-select 'second-tab)

;; Ensure pressing SPACE in the minibuffer actually inserts a space
(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; ===========================================================================
;; 5. RECENT FILES & HISTORY
;; ===========================================================================
(require 'recentf)
(setq recentf-save-file (expand-file-name "recentf" my/state-dir)
      recentf-max-saved-items 200)
(recentf-mode 1)

(setq savehist-file (expand-file-name "history" my/state-dir))
(savehist-mode 1)

;; ===========================================================================
;; 6. PROJECT MANAGEMENT (FOSSIL INTEGRATION)
;; ===========================================================================
(require 'project)
(setq project-list-file (expand-file-name "projects" my/state-dir)
      project-vc-extra-root-markers '(".fslckout" "_FOSSIL_"))

(defun my/project-ignores-fossil (orig-fn project dir)
  "Call ORIG-FN to get standard ignore patterns.
Then append Fossil's ignore globs for PROJECT in DIR."
  (let* ((ignores (funcall orig-fn project dir))
         (root (project-root project))
         (fossil-ignore (expand-file-name ".fossil-settings/ignore-glob" root)))
    (if (file-exists-p fossil-ignore)
        (with-temp-buffer
          (insert-file-contents fossil-ignore)
          (append ignores (split-string (buffer-string) "[\n\r,]+" t "[ \t]+")))
      ignores)))

(advice-add 'project-ignores :around #'my/project-ignores-fossil)

;; ===========================================================================
;; 7. TREE-SITTER & FILE ASSOCIATIONS
;; ===========================================================================
(defconst my/treesit-languages
  '((bash "https://github.com/tree-sitter/tree-sitter-bash")
    (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
    (json "https://github.com/tree-sitter/tree-sitter-json")
    (yaml "https://github.com/ikatyang/tree-sitter-yaml")
    (toml "https://github.com/tree-sitter/tree-sitter-toml")))

(defun my/has-c-compiler-p ()
  "Return non-nil if a C compiler is available for tree-sitter."
  (or (executable-find "cc") (executable-find "gcc") (executable-find "clang")))

;; Auto-install missing tree-sitter grammars silently on startup
(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (setq treesit-language-source-alist my/treesit-languages)
  (if (my/has-c-compiler-p)
      (dolist (lang my/treesit-languages)
        (unless (treesit-language-available-p (car lang))
          (condition-case err
              (treesit-install-language-grammar (car lang))
            (error (message "Tree-sitter compile error for %s: %s"
                            (car lang) (error-message-string err))))))
    (message "No C compiler found. Skipping Tree-sitter auto-compilation.")))

;; Map standard modes to their Tree-sitter counterparts if available.
;; Emacs 29+ uses `major-mode-remap-alist` to cleanly intercept and upgrade modes.
(defconst my/ts-mode-mappings
  '((bash . sh-mode)
    (python . python-mode)
    (json . js-json-mode)
    (yaml . yaml-mode)
    (toml . conf-toml-mode)))

(dolist (mapping my/ts-mode-mappings)
  (let ((lang (car mapping))
        (fallback-mode (cdr mapping)))
    (when (treesit-language-available-p lang)
      (add-to-list 'major-mode-remap-alist
                   (cons fallback-mode (intern (format "%s-ts-mode" lang)))))))

;; Markdown fallback
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;; ===========================================================================
;; 8. DEVELOPMENT (EGLOT, FLYMAKE, & VENV)
;; ===========================================================================
(require 'eglot)
(add-to-list 'warning-suppress-types '(eglot)) ;; Suppress LSP noise

(defun my/python-activate-venv ()
  "Locate and activate a venv or .venv in the current project root."
  (let ((root (if-let ((proj (project-current))) (project-root proj) default-directory)))
    (when-let ((venv-dir (car (directory-files root t "^\\.?venv$" t)))
               (bin-dir (expand-file-name "bin" venv-dir))
               (python-bin (expand-file-name "python" bin-dir)))
      (when (file-executable-p python-bin)
        (setenv "VIRTUAL_ENV" venv-dir)
        (setq-local exec-path (cons bin-dir exec-path))
        ;; path-separator ensures this works on Windows (;) and Unix (:)
        (setenv "PATH" (concat bin-dir path-separator (getenv "PATH")))
        (message "Activated venv: %s" venv-dir)))))

;; Attach Eglot and Venv activation to python-base-mode (covers ts and non-ts)
(add-hook 'python-base-mode-hook #'eglot-ensure)
(add-hook 'python-base-mode-hook #'my/python-activate-venv)

;; Standard Eglot/Flymake hooks for other modes
(dolist (hook '(bash-ts-mode-hook yaml-ts-mode-hook json-ts-mode-hook
                sh-mode-hook yaml-mode-hook js-json-mode-hook))
  (add-hook hook #'eglot-ensure))

(dolist (hook '(emacs-lisp-mode-hook markdown-mode-hook toml-ts-mode-hook conf-toml-mode-hook))
  (add-hook hook #'flymake-mode))

;; ===========================================================================
;; 9. VISUALS & TYPOGRAPHY
;; ===========================================================================
(load-theme 'modus-vivendi t)
(set-face-attribute 'default nil :font "Monospace" :height 150)
(setq-default line-spacing 0.2)

(column-number-mode 1)
(global-display-line-numbers-mode 1)

;; ===========================================================================
;; 10. ERGONOMIC KEYBINDINGS & NAVIGATION
;; ===========================================================================
(keymap-global-set "C-c r" #'recentf-open-files) ;; Fuzzy find recent files natively
(keymap-global-set "C-x C-b" #'ibuffer)          ;; Modern buffer management
(keymap-global-set "M-o" #'other-window)         ;; Fast window switching
(keymap-global-set "C-c p p" #'project-switch-project)
(keymap-global-set "C-c p f" #'project-find-file)

(provide 'init)
;;; init.el ends here
