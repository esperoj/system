;;; init.el --- Sovereign, Portable IDE for Perma Projects -*- lexical-binding: t; -*-

;;; Commentary:
;; Philosophy: Built-ins first.  Minimal external dependencies.  Emacs 29+.
;; Storage: Strict XDG compliance.  Code in config, generated files elsewhere.

;;; Code:

;; Forward declarations to silence byte-compiler warnings
(defvar tramp-persistency-file-name)
(defvar url-configuration-directory)
(defvar treesit-language-source-alist)
(defvar major-mode-remap-alist)

;; --- 0. XDG DIRECTORY SETUP (NO LITTERING) ---
(defvar xdg-state-home (or (getenv "XDG_STATE_HOME") "~/.local/state"))
(defvar xdg-cache-home (or (getenv "XDG_CACHE_HOME") "~/.cache"))
(defvar xdg-data-home  (or (getenv "XDG_DATA_HOME")  "~/.local/share"))

(defvar my/state-dir (expand-file-name "emacs/" xdg-state-home))
(defvar my/cache-dir (expand-file-name "emacs/" xdg-cache-home))
(defvar my/data-dir  (expand-file-name "emacs/" xdg-data-home))

;; Create all necessary directories in one pass
(dolist (dir (list my/state-dir my/cache-dir my/data-dir
                   (expand-file-name "backups" my/state-dir)
                   (expand-file-name "auto-save" my/state-dir)))
  (make-directory dir t))

;; Strict XDG paths for built-in variables
(setq user-emacs-directory my/state-dir
      package-user-dir (expand-file-name "elpa" my/state-dir)
      backup-directory-alist `(("." . ,(expand-file-name "backups" my/state-dir)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" my/state-dir) t))
      create-lockfiles nil
      custom-file (expand-file-name "custom.el" my/state-dir)
      tramp-persistency-file-name (expand-file-name "tramp" my/cache-dir)
      url-configuration-directory (expand-file-name "url/" my/cache-dir))

(when (boundp 'native-comp-eln-load-path)
  (add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" my/cache-dir)))

(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; --- 1. STARTUP & UI ---
(setq gc-cons-threshold 100000000
      inhibit-startup-screen t
      inhibit-startup-message t
      initial-scratch-message nil
      use-dialog-box nil)

(add-hook 'emacs-startup-hook (lambda () (setq gc-cons-threshold 800000)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; --- 2. EXTERNAL PACKAGES ---
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

;; --- 3. COMPLETION (ICOMPLETE & FLEX) ---
(icomplete-vertical-mode 1)
(setq icomplete-show-matches-on-no-input t
      icomplete-hide-common-prefix nil)

;; Make searching "smarter" using Emacs' built-in fuzzy/substring matching.
(setq completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic))))

;; Ensure pressing SPACE in the minibuffer actually inserts a space
(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; In-buffer code completion settings
(setq completions-detailed t
      completions-format 'one-column
      completions-max-height 15
      completion-cycle-threshold 3
      tab-always-indent 'complete
      completion-auto-select 'second-tab)

;; --- 4. RECENT FILES ---
(require 'recentf)
(setq recentf-save-file (expand-file-name "recentf" my/state-dir)
      recentf-max-saved-items 200)
(recentf-mode 1)

(defun my/recent-files ()
  "Fuzzy-find and open a recently used file."
  (interactive)
  (when-let ((file (completing-read "Recent file: " recentf-list nil t)))
    (find-file file)))

(keymap-global-set "C-c r" #'my/recent-files)

;; --- 5. PROJECT MANAGEMENT ---
(require 'project)
(setq project-list-file (expand-file-name "projects" my/state-dir)
      project-vc-extra-root-markers '(".fslckout" "_FOSSIL_"))

;; Make project.el respect Fossil's ignore-glob settings
(defun my/project-ignores-fossil (orig-fn project dir)
  "Append Fossil's ignore globs to Emacs' standard `project-ignores'."
  (let* ((ignores (funcall orig-fn project dir))
         (root (project-root project))
         (fossil-ignore (expand-file-name ".fossil-settings/ignore-glob" root)))
    (if (file-exists-p fossil-ignore)
        (with-temp-buffer
          (insert-file-contents fossil-ignore)
          (append ignores (split-string (buffer-string) "[\n\r,]+" t "[ \t]+")))
      ignores)))

(advice-add 'project-ignores :around #'my/project-ignores-fossil)

;; --- 6. FILE ASSOCIATIONS & TREE-SITTER ---
(setq treesit-language-source-alist
      '((bash "https://github.com/tree-sitter/tree-sitter-bash")
        (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
        (json "https://github.com/tree-sitter/tree-sitter-json")
        (yaml "https://github.com/ikatyang/tree-sitter-yaml")
        (toml "https://github.com/tree-sitter/tree-sitter-toml")))

(defun my/has-c-compiler-p ()
  "Return non-nil if a C compiler is available for tree-sitter."
  (or (executable-find "cc")
      (executable-find "gcc")
      (executable-find "clang")))

;; Auto-install missing tree-sitter grammars silently on startup
(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (if (my/has-c-compiler-p)
      (dolist (lang treesit-language-source-alist)
        (unless (treesit-language-available-p (car lang))
          (condition-case err
              (treesit-install-language-grammar (car lang))
            (error
             (message "Tree-sitter compile error for %s: %s" (car lang) (error-message-string err))))))
    (message "No C compiler (cc/gcc/clang) found. Skipping Tree-sitter auto-compilation.")))

;; ONLY remap major modes to Tree-Sitter IF the grammar successfully compiled.
;; This prevents Emacs from throwing missing shared object errors.
(when (treesit-language-available-p 'bash)   (add-to-list 'major-mode-remap-alist '(sh-mode . bash-ts-mode)))
(when (treesit-language-available-p 'python) (add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode)))
(when (treesit-language-available-p 'json)   (add-to-list 'major-mode-remap-alist '(js-json-mode . json-ts-mode)))
(when (treesit-language-available-p 'yaml)   (add-to-list 'major-mode-remap-alist '(yaml-mode . yaml-ts-mode)))
(when (treesit-language-available-p 'toml)   (add-to-list 'major-mode-remap-alist '(conf-toml-mode . toml-ts-mode)))

;; Fallback auto-modes for external packages
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))
(when (treesit-language-available-p 'yaml) (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-ts-mode)))
(when (treesit-language-available-p 'toml) (add-to-list 'auto-mode-alist '("\\.toml\\'"  . toml-ts-mode)))
(when (treesit-language-available-p 'json) (add-to-list 'auto-mode-alist '("\\.json\\'"  . json-ts-mode)))

;; --- 7. DEVELOPMENT (EGLOT, FLYMAKE, & VENV) ---
(require 'eglot)

;; Suppress annoying popups when Eglot can't find a Language Server executable yet.
(add-to-list 'warning-suppress-types '(eglot))

(defun my/python-venv-activate ()
  "Locate and activate a venv or .venv in the current project root."
  (interactive)
  (let ((root (if-let ((proj (project-current))) (project-root proj) default-directory)))
    (when-let ((venv-path (car (directory-files root t "^\\.?venv$" t)))
               (bin (expand-file-name "bin" venv-path))
               (python (expand-file-name "python" bin)))
      (when (file-executable-p python)
        (setenv "VIRTUAL_ENV" venv-path)
        (setq-local exec-path (cons bin exec-path))
        (setenv "PATH" (concat bin ":" (getenv "PATH")))
        (message "Activated venv: %s" venv-path)))))

;; Attach Eglot and Venv activation to python-base-mode (covers both ts and non-ts python modes)
(add-hook 'python-base-mode-hook #'eglot-ensure)
(add-hook 'python-base-mode-hook #'my/python-venv-activate)

;; Standard hooks for other modes (safe for both ts and non-ts variants)
(dolist (hook '(bash-ts-mode-hook yaml-ts-mode-hook json-ts-mode-hook
                sh-mode-hook yaml-mode-hook js-json-mode-hook))
  (add-hook hook #'eglot-ensure))

(dolist (hook '(emacs-lisp-mode-hook markdown-mode-hook toml-ts-mode-hook conf-toml-mode-hook))
  (add-hook hook #'flymake-mode))

;; --- 8. VISUALS & TYPOGRAPHY ---
(load-theme 'modus-vivendi t)
(set-face-attribute 'default nil :font "Monospace" :height 150)
(setq-default line-spacing 0.2)

(column-number-mode 1)
(global-display-line-numbers-mode 1)

(provide 'init)
;;; init.el ends here
