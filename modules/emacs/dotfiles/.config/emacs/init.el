;;; init.el --- Sovereign, Zero-Lag IDE -*- lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; 0. Permanently Disable Native-Compilation Loops & CPU Thrashing
;; -----------------------------------------------------------------------------
;; 1. Disable JIT compilation and deny all files from being queued
(setq native-comp-jit-compilation nil
      native-comp-speed -1
      native-comp-async-report-warnings-errors nil
      native-comp-warning-on-missing-source nil
      native-comp-jit-compilation-deny-list '(".*"))

(when (boundp 'native-comp-deferred-compilation)
  (setq native-comp-deferred-compilation nil))
(when (boundp 'native-comp-deferred-compilation-deny-list)
  (setq native-comp-deferred-compilation-deny-list '(".*")))

;; 2. Intercept and neutralize async compilation workers directly
;; This stops background compiling/uncompressing of debian-ispell and system .el.gz files
(when (fboundp 'native-compile-async)
  (advice-add #'native-compile-async :override #'ignore))
(when (fboundp 'comp-run-async-workers)
  (advice-add #'comp-run-async-workers :override #'ignore))

;; Clean up the log buffer if it was created before init.el ran
(add-hook 'emacs-startup-hook
          (lambda ()
            (when-let* ((buf (get-buffer "*Async-native-compile-log*")))
              (kill-buffer buf))))

;; -----------------------------------------------------------------------------
;; 1. Garbage Collection & Process Pipe Tuning (Zero UI Freezes)
;; -----------------------------------------------------------------------------
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))

;; Read process pipes in 1MB chunks (Emacs default is 4KB; required for smooth LSP)
(setq read-process-output-max (* 1024 1024))

;; -----------------------------------------------------------------------------
;; 2. System PATH Setup (Ensures ty, uv, ruff are found in GUI Emacs)
;; -----------------------------------------------------------------------------
(dolist (dir (list (expand-file-name "~/.local/bin")
                   (expand-file-name "~/.cargo/bin")
                   "/usr/local/bin"))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

;; -----------------------------------------------------------------------------
;; 3. Natural Default File Locations (No XDG Overrides)
;; -----------------------------------------------------------------------------
;; Let Emacs manage its own directory (~/.config/emacs or ~/.emacs.d)
(let ((backup-dir (locate-user-emacs-file "backups/"))
      (autosave-dir (locate-user-emacs-file "auto-save/")))
  (dolist (dir (list backup-dir autosave-dir))
    (unless (file-directory-p dir)
      (make-directory dir t)))
  (setq backup-directory-alist `(("." . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,autosave-dir t))))

(setq create-lockfiles nil
      custom-file (locate-user-emacs-file "custom.el"))

(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; -----------------------------------------------------------------------------
;; 4. UI Cleaning & Shell Echo Message Silencing
;; -----------------------------------------------------------------------------
(setq inhibit-startup-screen t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Silence the verbose "Setting up indent for shell type bash" echo area spam
(defun my/suppress-sh-indent-messages (orig-fun &rest args)
  "Silence verbose echo messages when sh-script sets up indentation."
  (let ((inhibit-message t)
        (message-log-max nil))
    (apply orig-fun args)))

(with-eval-after-load 'sh-script
  (advice-add 'sh-set-shell :around #'my/suppress-sh-indent-messages)
  (advice-add 'sh-make-vars-local :around #'my/suppress-sh-indent-messages))

;; -----------------------------------------------------------------------------
;; 5. Core Editing Ergonomics
;; -----------------------------------------------------------------------------
(global-font-lock-mode 1)
(setq font-lock-maximum-decoration t)
(setq-default font-lock-maximum-decoration t)

(repeat-mode 1)
(save-place-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)

;; Non-blocking auto-revert
(setq auto-revert-avoid-polling t
      auto-revert-check-vc-info nil
      auto-revert-stop-on-user-input t)
(global-auto-revert-mode 1)

(setq-default indent-tabs-mode nil)

;; -----------------------------------------------------------------------------
;; 6. Built-in Completion (Vertical Minibuffer + TAB Completion)
;; -----------------------------------------------------------------------------
(setq tab-always-indent 'complete
      completions-detailed t
      completion-auto-select t
      completions-max-height 12)

(icomplete-vertical-mode 1)
(setq icomplete-show-matches-on-no-input t
      completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic)))
      completions-format 'one-column)

;; Ensure pressing Space inside minibuffer inserts a normal space
(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; -----------------------------------------------------------------------------
;; 7. History, State & Project Search
;; -----------------------------------------------------------------------------
(require 'recentf)
(setq recentf-save-file (locate-user-emacs-file "recentf")
      recentf-max-saved-items 200)
(recentf-mode 1)

(setq savehist-file (locate-user-emacs-file "history"))
(savehist-mode 1)

(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))

;; -----------------------------------------------------------------------------
;; 8. Magit & Conflict Resolution
;; -----------------------------------------------------------------------------
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
;; 9. Languages & Tree-sitter Remapping
;; -----------------------------------------------------------------------------
(when (require 'yaml-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode)))

(when (require 'markdown-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))
  (add-hook 'markdown-mode-hook #'visual-line-mode))

;; Remap major modes to tree-sitter modes only if the grammar is available on disk
(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (require 'treesit)
  (setq treesit-font-lock-level 4)
  (dolist (mapping '((bash   sh-mode      bash-ts-mode)
                     (python python-mode  python-ts-mode)
                     (json   js-json-mode json-ts-mode)))
    (when (treesit-language-available-p (nth 0 mapping))
      (add-to-list 'major-mode-remap-alist
                   (cons (nth 1 mapping) (nth 2 mapping))))))

;; -----------------------------------------------------------------------------
;; 10. Robust Python Project & LSP Integration
;; -----------------------------------------------------------------------------
;; Recognize Python projects even without .git (via .venv, pyproject.toml, etc.)
(defun my/project-try-python (dir)
  "Locate Python project root for Eglot even outside Git repositories."
  (when-let* ((root (locate-dominating-file
                     dir
                     (lambda (d)
                       (or (file-directory-p (expand-file-name ".venv" d))
                           (file-directory-p (expand-file-name "venv" d))
                           (file-exists-p (expand-file-name "pyproject.toml" d))
                           (file-exists-p (expand-file-name "setup.py" d))
                           (file-exists-p (expand-file-name "requirements.txt" d)))))))
    (cons 'transient root)))

(with-eval-after-load 'project
  (add-hook 'project-find-functions #'my/project-try-python 80))

;; Locate Python venv (.venv, venv, or active $VIRTUAL_ENV)
(defun my/find-python-venv ()
  "Find local .venv or venv dominating current directory, or from environment."
  (let ((py-rel (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python")))
    (or
     ;; 1. Check parent directories for .venv or venv
     (when-let* ((root (locate-dominating-file
                        default-directory
                        (lambda (dir)
                          (or (file-executable-p (expand-file-name (concat ".venv/" py-rel) dir))
                              (file-executable-p (expand-file-name (concat "venv/" py-rel) dir)))))))
       (or (let ((v (expand-file-name ".venv" root)))
             (when (file-executable-p (expand-file-name py-rel v)) v))
           (let ((v (expand-file-name "venv" root)))
             (when (file-executable-p (expand-file-name py-rel v)) v))))
     ;; 2. Fall back to active VIRTUAL_ENV environment variable
     (when-let* ((env-venv (getenv "VIRTUAL_ENV")))
       (when (file-executable-p (expand-file-name py-rel env-venv))
         (directory-file-name env-venv))))))

(defun my/python-activate-venv ()
  "Activate local Python venv for current buffer safely."
  (when-let* ((venv-dir (my/find-python-venv)))
    (let* ((bin-dir (expand-file-name (if (eq system-type 'windows-nt) "Scripts" "bin") venv-dir))
           (py-bin (expand-file-name (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python") venv-dir))
           (old-path (or (getenv "PATH") "")))
      ;; Prepend .venv/bin to buffer-local PATH and exec-path
      (setq-local process-environment
                  (cons (format "VIRTUAL_ENV=%s" venv-dir)
                        (cons (format "PATH=%s%s%s" bin-dir path-separator old-path)
                              (seq-remove (lambda (e) (string-prefix-p "VIRTUAL_ENV=" e))
                                          process-environment))))
      (setq-local exec-path (cons bin-dir (remove bin-dir exec-path)))
      (setq-local python-shell-interpreter py-bin)
      venv-dir)))

;; Python LSP command selector (prefers ty, falls back cleanly to alternatives)
(defun my/python-lsp-command ()
  "Return command for the first available Python language server."
  (cond
   ((executable-find "ty") '("ty" "server"))
   ((executable-find "basedpyright-langserver") '("basedpyright-langserver" "--stdio"))
   ((executable-find "pyright-langserver") '("pyright-langserver" "--stdio"))
   ((executable-find "pylsp") '("pylsp"))
   ((executable-find "ruff") '("ruff" "server"))
   (t nil)))

(setq eglot-autoshutdown t
      eglot-events-buffer-size 0
      eldoc-idle-delay 0.4
      eldoc-echo-area-use-multiline-p nil)

(with-eval-after-load 'eglot
  (add-to-list 'warning-suppress-types '(eglot))
  ;; Register Astral ty server with automatic fallback
  (add-to-list 'eglot-server-programs
               `(((python-mode :language-id "python")
                  (python-ts-mode :language-id "python"))
                 . ,(lambda (&optional _interactive _project)
                      (or (my/python-lsp-command)
                          '("ty" "server"))))))

(defun my/python-mode-setup ()
  "Setup Python buffer, activate venv, and connect to language server."
  (my/python-activate-venv)
  (if (my/python-lsp-command)
      (progn
        (require 'eglot)
        (condition-case err
            (eglot-ensure)
          (error (message "Eglot: %s" (error-message-string err)))))
    (message "Note: No Python LSP found (checked ty, basedpyright, pyright, ruff, pylsp). Install: uv tool install ty")))

;; Explicitly hook BOTH modes so setup runs regardless of Tree-sitter remapping
(add-hook 'python-mode-hook #'my/python-mode-setup)
(add-hook 'python-ts-mode-hook #'my/python-mode-setup)

;; -----------------------------------------------------------------------------
;; 11. Secondary Language LSP Hooks (Bash, JSON, YAML)
;; -----------------------------------------------------------------------------
(defun my/bash-eglot-ensure ()
  (when (executable-find "bash-language-server")
    (ignore-errors (eglot-ensure))))
(add-hook 'sh-mode-hook #'my/bash-eglot-ensure)
(add-hook 'bash-ts-mode-hook #'my/bash-eglot-ensure)

(setq js-indent-level 2)
(defun my/json-eglot-ensure ()
  (when (or (executable-find "vscode-json-language-server")
            (executable-find "json-languageserver"))
    (ignore-errors (eglot-ensure))))
(add-hook 'json-ts-mode-hook #'my/json-eglot-ensure)
(add-hook 'js-json-mode-hook #'my/json-eglot-ensure)

(defun my/yaml-eglot-ensure ()
  (when (executable-find "yaml-language-server")
    (ignore-errors (eglot-ensure))))
(add-hook 'yaml-mode-hook #'my/yaml-eglot-ensure)
(add-hook 'yaml-ts-mode-hook #'my/yaml-eglot-ensure)

;; -----------------------------------------------------------------------------
;; 12. Visual Theme & Ergonomics
;; -----------------------------------------------------------------------------
(load-theme 'modus-vivendi t)

(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Monospace" :height 140))
(add-to-list 'default-frame-alist '(font . "Monospace-14"))

(setq-default line-spacing 0.15)
(column-number-mode 1)

;; Line numbers restricted strictly to code and text buffers
(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; -----------------------------------------------------------------------------
;; 13. Ergonomic Keybindings
;; -----------------------------------------------------------------------------
;; Git: Magit status
(keymap-global-set "C-x g" #'magit-status)

;; Fast Recent Files via built-in completing-read
(defun my/recentf-open ()
  "Find recent file using built-in completing-read."
  (interactive)
  (find-file (completing-read "Recent file: " recentf-list nil t)))
(keymap-global-set "C-x C-r" #'my/recentf-open)

;; Fast line commenting
(keymap-global-set "M-/" #'comment-line)

;; Safe Buffer Formatting (uses Eglot if supported, falls back to ruff format)
(defun my/format-buffer ()
  "Format current buffer via Eglot or ruff."
  (interactive)
  (cond
   ((and (bound-and-true-p eglot--managed-mode)
         (eglot-server-capable :documentFormattingProvider))
    (eglot-format-buffer))
   ((and (derived-mode-p 'python-mode 'python-ts-mode)
         (executable-find "ruff"))
    (shell-command-on-region (point-min) (point-max) "ruff format -" (current-buffer) t))
   (t
    (message "No formatting provider available."))))

;; Eglot LSP shortcuts under `C-c l`
(with-eval-after-load 'eglot
  (keymap-set eglot-mode-map "C-c l r" #'eglot-rename)
  (keymap-set eglot-mode-map "C-c l a" #'eglot-code-actions)
  (keymap-set eglot-mode-map "C-c l f" #'my/format-buffer)
  (keymap-set eglot-mode-map "C-c l h" #'eldoc))

(provide 'init)
;;; init.el ends here
