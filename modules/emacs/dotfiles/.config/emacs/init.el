;;; init.el --- Sovereign, Responsive Debian IDE -*- lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; 0. XDG Directories & File Storage
;; -----------------------------------------------------------------------------
(defconst my/state-dir (expand-file-name "emacs/" (or (getenv "XDG_STATE_HOME") "~/.local/state")))
(defconst my/cache-dir (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache")))

(dolist (dir (list my/state-dir
                   my/cache-dir
                   (expand-file-name "backups" my/state-dir)
                   (expand-file-name "auto-save" my/state-dir)
                   (expand-file-name "tree-sitter" my/state-dir)))
  (make-directory dir t))

(setq user-emacs-directory my/state-dir
      backup-directory-alist `(("." . ,(expand-file-name "backups" my/state-dir)))
      ;; Trailing slash ensures auto-saves are stored inside the directory
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save/" my/state-dir) t))
      create-lockfiles nil
      custom-file (expand-file-name "custom.el" my/state-dir)
      tramp-persistency-file-name (expand-file-name "tramp" my/cache-dir))

(when (boundp 'native-comp-eln-load-path)
  (add-to-list 'native-comp-eln-load-path
               (expand-file-name "eln-cache/" my/cache-dir)))

(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; -----------------------------------------------------------------------------
;; 1. UI & Performance Tuning (Fixes Buffer-Open Freezes)
;; -----------------------------------------------------------------------------
(setq gc-cons-threshold 100000000
      gc-cons-percentage 0.2
      inhibit-startup-screen t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

;; 1MB IPC buffer prevents stutter when language servers output large JSON chunks
(setq read-process-output-max (* 1024 1024)
      process-adaptive-read-buffering nil)

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold 67108864)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; -----------------------------------------------------------------------------
;; 2. Syntax Highlighting Engine & Ergonomics
;; -----------------------------------------------------------------------------
;; Tree-sitter: Level 4 enables full highlighting (variables, calls, operators)
(setq treesit-font-lock-level 4
      font-lock-maximum-decoration t)

(pixel-scroll-precision-mode 1)
(repeat-mode 1)
(save-place-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)

;; Prevent background git queries from freezing the UI
(setq auto-revert-avoid-polling t
      auto-revert-check-vc-info nil)
(global-auto-revert-mode 1)

(setq-default indent-tabs-mode nil)

;; -----------------------------------------------------------------------------
;; 3. Completion (Icomplete + Flex)
;; -----------------------------------------------------------------------------
(icomplete-vertical-mode 1)

(setq icomplete-show-matches-on-no-input t
      completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic)))
      completions-detailed t
      completions-max-height 15
      tab-always-indent 'complete)

(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; -----------------------------------------------------------------------------
;; 4. History, State & Project Search
;; -----------------------------------------------------------------------------
(require 'recentf)
(setq recentf-save-file (expand-file-name "recentf" my/state-dir)
      recentf-max-saved-items 200)
(recentf-mode 1)

(setq savehist-file (expand-file-name "history" my/state-dir))
(savehist-mode 1)

(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))

;; -----------------------------------------------------------------------------
;; 5. Magit & Fast Conflict Detection
;; -----------------------------------------------------------------------------
;; Magit binds `C-x g` to `magit-status` by default.
(with-eval-after-load 'magit
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1))

(defun my/maybe-smerge-mode ()
  "Enable `smerge-mode' cheaply without scanning large non-VC buffers."
  (when (and buffer-file-name
             vc-mode
             (not (file-remote-p buffer-file-name))
             (< (buffer-size) 1000000))
    (save-excursion
      (save-match-data
        (goto-char (point-min))
        (when (re-search-forward "^<<<<<<< " 65536 t)
          (smerge-mode 1))))))

(add-hook 'find-file-hook #'my/maybe-smerge-mode)

;; -----------------------------------------------------------------------------
;; 6. Built-in Tree-sitter (Auto-Installs Missing Grammars)
;; -----------------------------------------------------------------------------
(when (and (fboundp 'treesit-available-p)
           (treesit-available-p))

  (require 'treesit)

  (setq treesit-language-source-alist
        '((bash   "https://github.com/tree-sitter/tree-sitter-bash" "v0.20.0")
          (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
          (json   "https://github.com/tree-sitter/tree-sitter-json" "v0.20.2")
          (yaml   "https://github.com/ikatyang/tree-sitter-yaml")
          (toml   "https://github.com/tree-sitter/tree-sitter-toml" "v0.20.0")))

  ;; Check and auto-compile missing grammars using Emacs' native compiler
  (dolist (recipe treesit-language-source-alist)
    (let ((lang (car recipe)))
      (unless (treesit-language-available-p lang)
        (message "Tree-sitter: Compiling missing grammar for %s..." lang)
        (condition-case err
            (treesit-install-language-grammar lang)
          (error (message "Tree-sitter: Failed to compile %s: %s"
                          lang (error-message-string err)))))))

  ;; Remap classic modes to ts-modes ONLY when the grammar is verified on disk.
  ;; If a grammar is missing, keep python-mode/sh-mode so highlighting NEVER breaks.
  (dolist (mapping '((bash   sh-mode      bash-ts-mode)
                     (python python-mode  python-ts-mode)
                     (json   js-json-mode json-ts-mode)))
    (when (treesit-language-available-p (nth 0 mapping))
      (add-to-list 'major-mode-remap-alist
                   (cons (nth 1 mapping) (nth 2 mapping))))))

;; -----------------------------------------------------------------------------
;; 7. Workflows & Eglot LSP (Python `ty`, Bash, JSON, YAML, Markdown)
;; -----------------------------------------------------------------------------
(require 'eglot)
(add-to-list 'warning-suppress-types '(eglot))

(setq eglot-autoshutdown t
      eglot-events-buffer-size 0
      eldoc-idle-delay 0.3)

;; Register Astral `ty` alongside standard Python language servers
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((python-mode python-ts-mode)
                 . (eglot-alternatives
                    '(("ty" "server")
                      ("pyright-langserver" "--stdio")
                      ("pylsp"))))))

(defun my/eglot-ensure-if-any (&rest executables)
  "Enable Eglot safely only when one of EXECUTABLES is found in PATH."
  (catch 'found
    (dolist (exe executables)
      (when (executable-find exe)
        (ignore-errors (eglot-ensure))
        (throw 'found t)))))

;; Python: Instant O(1) venv detection without blocking directory scans
(defun my/python-activate-venv ()
  "Activate local Python venv for current buffer safely."
  (let* ((root (or (when-let* ((proj (project-current)))
                     (project-root proj))
                   default-directory))
         (py-rel (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python"))
         (bin-rel (if (eq system-type 'windows-nt) "Scripts" "bin"))
         (venv-dir (seq-find (lambda (dir)
                               (file-executable-p (expand-file-name py-rel dir)))
                             (list (expand-file-name ".venv" root)
                                   (expand-file-name "venv" root)))))
    (when venv-dir
      (let* ((bin-dir (expand-file-name bin-rel venv-dir))
             (py-bin (expand-file-name py-rel venv-dir))
             (old-path (or (getenv "PATH" process-environment) ""))
             (clean-env (seq-filter (lambda (env)
                                      (not (or (string-prefix-p "VIRTUAL_ENV=" env)
                                               (string-prefix-p "PATH=" env))))
                                    process-environment)))
        (setq-local process-environment
                    (append (list (format "VIRTUAL_ENV=%s" venv-dir)
                                  (format "PATH=%s%s%s" bin-dir path-separator old-path))
                            clean-env))
        (setq-local exec-path (cons bin-dir (delete bin-dir exec-path)))
        (when (boundp 'python-shell-interpreter)
          (setq-local python-shell-interpreter py-bin))))))

(defun my/python-mode-setup ()
  "Setup Python buffer safely without breaking font-lock."
  (ignore-errors (my/python-activate-venv))
  (ignore-errors (my/eglot-ensure-if-any "ty" "pyright-langserver" "pylsp")))

(add-hook 'python-base-mode-hook #'my/python-mode-setup)

;; Bash LSP
(dolist (hook '(bash-ts-mode-hook sh-mode-hook))
  (add-hook hook
            (lambda ()
              (my/eglot-ensure-if-any "bash-language-server"))))

;; JSON LSP
(setq js-indent-level 2)
(dolist (hook '(json-ts-mode-hook js-json-mode-hook))
  (add-hook hook
            (lambda ()
              (my/eglot-ensure-if-any "vscode-json-language-server"
                                      "json-languageserver"))))

;; YAML LSP
(dolist (hook '(yaml-mode-hook yaml-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (my/eglot-ensure-if-any "yaml-language-server"))))

;; Markdown configuration
(setq markdown-command "pandoc -f markdown -t html --standalone")
(add-hook 'markdown-mode-hook #'visual-line-mode)

;; -----------------------------------------------------------------------------
;; 8. Visuals
;; -----------------------------------------------------------------------------
(load-theme 'modus-vivendi t)

;; Set font safely for both standalone GUI and emacsclient frames
(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Monospace" :height 140))
(add-to-list 'default-frame-alist '(font . "Monospace-14"))

(setq-default line-spacing 0.15)
(column-number-mode 1)
(global-display-line-numbers-mode 1)

(provide 'init)
;;; init.el ends here
