;;; init.el --- Fast, Smooth & Ergonomic IDE -*- lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; 1. Standard Modern Memory & Process Tuning (Smooth LSP & No Freezes)
;; -----------------------------------------------------------------------------
;; Sane modern threshold: 32MB (prevents GC pauses on every keystroke during LSP)
(setq gc-cons-threshold (* 32 1024 1024)
      gc-cons-percentage 0.1)

;; Run garbage collection only when idle for 5 seconds
(run-with-idle-timer 5.0 t #'garbage-collect)

;; Read LSP/subprocess pipes in 1MB chunks (standard for Eglot)
(setq read-process-output-max (* 1024 1024))

;; -----------------------------------------------------------------------------
;; 2. System PATH Setup
;; -----------------------------------------------------------------------------
(dolist (dir (list (expand-file-name "~/.local/bin")
                   (expand-file-name "~/.cargo/bin")
                   "/usr/local/bin"))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (getenv "PATH")))))

;; -----------------------------------------------------------------------------
;; 3. File Locations & Clean Defaults
;; -----------------------------------------------------------------------------
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
;; 4. UI Cleaning & Message Silencing
;; -----------------------------------------------------------------------------
(setq inhibit-startup-screen t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; Silence verbose "Setting up indent for shell type bash" echo area spam
(defun my/suppress-sh-indent-messages (orig-fun &rest args)
  (let ((inhibit-message t)
        (message-log-max nil))
    (apply orig-fun args)))

(with-eval-after-load 'sh-script
  (advice-add 'sh-set-shell :around #'my/suppress-sh-indent-messages)
  (advice-add 'sh-make-vars-local :around #'my/suppress-sh-indent-messages))

;; -----------------------------------------------------------------------------
;; 5. Core Editing Ergonomics & Emacs 30 Built-ins
;; -----------------------------------------------------------------------------
(global-font-lock-mode 1)
(repeat-mode 1)
(save-place-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)
(which-key-mode 1)       ; Built-in in Emacs 30.1
(editorconfig-mode 1)    ; Built-in in Emacs 30.1

;; Non-blocking auto-revert
(setq auto-revert-avoid-polling t
      auto-revert-check-vc-info nil
      auto-revert-stop-on-user-input t)
(global-auto-revert-mode 1)

(setq-default indent-tabs-mode nil)

;; -----------------------------------------------------------------------------
;; 6. Fast Built-in Minibuffer Completion (No Flex Stutter)
;; -----------------------------------------------------------------------------
(setq tab-always-indent 'complete
      completions-detailed t
      completion-auto-select t
      completions-max-height 12
      completions-sort 'historical  ; Emacs 30.1
      icomplete-compute-delay 0.1   ; Short debounce to prevent typing freeze
      icomplete-show-matches-on-no-input t)

;; Order styles: Fast prefixes first, heavy 'flex' fuzzy matching last
(setq completion-styles '(basic substring partial-completion flex)
      completion-category-defaults nil
      completion-category-overrides '((file (styles basic substring partial-completion))))

(icomplete-vertical-mode 1)
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
  "Enable `smerge-mode' cheaply without regex scanning large files."
  (when (and buffer-file-name
             vc-mode
             (not (file-remote-p buffer-file-name))
             (< (buffer-size) 500000))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " 10000 t)
        (smerge-mode 1)))))

(add-hook 'find-file-hook #'my/maybe-smerge-mode)

;; -----------------------------------------------------------------------------
;; 9. Tree-sitter Setup (Optimized Font-Lock Level 3)
;; -----------------------------------------------------------------------------
(when (require 'yaml-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode)))

(when (require 'markdown-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))
  (add-hook 'markdown-mode-hook #'visual-line-mode))

(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (require 'treesit)
  ;; Level 3 provides full syntax colors without the heavy typing latency of level 4
  (setq treesit-font-lock-level 3)

  (setq treesit-language-source-alist
        '((bash   "https://github.com/tree-sitter/tree-sitter-bash")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (json   "https://github.com/tree-sitter/tree-sitter-json")))

  (defun my/treesit-install-grammars ()
    "Install missing configured Tree-sitter grammars."
    (interactive)
    (dolist (source treesit-language-source-alist)
      (let ((lang (car source)))
        (unless (treesit-language-available-p lang)
          (treesit-install-language-grammar lang)))))

  (dolist (mapping '((bash   sh-mode      bash-ts-mode)
                     (python python-mode  python-ts-mode)
                     (json   js-json-mode json-ts-mode)))
    (when (treesit-language-available-p (nth 0 mapping))
      (add-to-list 'major-mode-remap-alist
                   (cons (nth 1 mapping) (nth 2 mapping))))))

;; -----------------------------------------------------------------------------
;; 10. Project & Fast Python Venv + Eglot
;; -----------------------------------------------------------------------------
;; Fast built-in project markers (uses Emacs 30 native C/Elisp root detection)
(with-eval-after-load 'project
  (setq project-vc-extra-root-markers '("pyproject.toml" "setup.py" "requirements.txt" ".venv")))

;; Fast, cached venv search (checks local directory first)
(defun my/find-python-venv ()
  "Find local .venv or active VIRTUAL_ENV without deep filesystem traversal."
  (let ((py-rel (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python")))
    (or
     (let ((local-venv (expand-file-name ".venv" default-directory)))
       (when (file-executable-p (expand-file-name py-rel local-venv))
         local-venv))
     (when-let* ((root (locate-dominating-file default-directory ".venv")))
       (let ((v (expand-file-name ".venv" root)))
         (when (file-executable-p (expand-file-name py-rel v)) v)))
     (when-let* ((env-venv (getenv "VIRTUAL_ENV")))
       (when (file-executable-p (expand-file-name py-rel env-venv))
         (directory-file-name env-venv))))))

(defun my/python-activate-venv ()
  "Activate local Python venv for current buffer safely."
  (when-let* ((venv-dir (my/find-python-venv)))
    (let* ((bin-dir (expand-file-name (if (eq system-type 'windows-nt) "Scripts" "bin") venv-dir))
           (py-bin (expand-file-name (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python") venv-dir))
           (old-path (or (getenv "PATH") "")))
      (setq-local process-environment
                  (cons (format "VIRTUAL_ENV=%s" venv-dir)
                        (cons (format "PATH=%s%s%s" bin-dir path-separator old-path)
                              (seq-remove (lambda (e) (string-prefix-p "VIRTUAL_ENV=" e))
                                          process-environment))))
      (setq-local exec-path (cons bin-dir (remove bin-dir exec-path)))
      (setq-local python-shell-interpreter py-bin)
      venv-dir)))

(defun my/python-lsp-command ()
  (cond
   ((executable-find "ty") '("ty" "server"))
   ((executable-find "basedpyright-langserver") '("basedpyright-langserver" "--stdio"))
   ((executable-find "pyright-langserver") '("pyright-langserver" "--stdio"))
   ((executable-find "pylsp") '("pylsp"))
   ((executable-find "ruff") '("ruff" "server"))
   (t nil)))

;; Eglot & Flymake Performance Optimization
(setq eglot-autoshutdown t
      eglot-sync-connect nil           ; Never block the UI on connection
      eglot-events-buffer-size 0       ; Disable event buffer logging
      eldoc-idle-delay 0.5             ; Avoid spamming eldoc on every cursor hop
      eldoc-echo-area-use-multiline-p nil
      flymake-no-changes-timeout 0.5)  ; Debounce flymake linting while typing

(with-eval-after-load 'eglot
  (add-to-list 'warning-suppress-types '(eglot))
  ;; Disable expensive JSON pretty-printing in Eglot
  (fset #'jsonrpc--log-event #'ignore)

  (add-to-list 'eglot-server-programs
               `(((python-mode :language-id "python")
                  (python-ts-mode :language-id "python"))
                 . ,(lambda (&optional _interactive _project)
                      (or (my/python-lsp-command) '("ty" "server"))))))

(defun my/python-mode-setup ()
  (my/python-activate-venv)
  (when (my/python-lsp-command)
    (require 'eglot)
    (condition-case err
        (eglot-ensure)
      (error (message "Eglot: %s" (error-message-string err))))))

(add-hook 'python-mode-hook #'my/python-mode-setup)
(add-hook 'python-ts-mode-hook #'my/python-mode-setup)

;; -----------------------------------------------------------------------------
;; 11. Secondary Language LSP Hooks
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

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

;; -----------------------------------------------------------------------------
;; 13. Ergonomic Keybindings
;; -----------------------------------------------------------------------------
(keymap-global-set "C-x g" #'magit-status)

(defun my/recentf-open ()
  "Find recent file using built-in completing-read."
  (interactive)
  (find-file (completing-read "Recent file: " recentf-list nil t)))
(keymap-global-set "C-x C-r" #'my/recentf-open)

(keymap-global-set "M-/" #'comment-line)

(defun my/format-buffer ()
  "Format current buffer via Eglot or ruff."
  (interactive)
  (cond
   ((and (bound-and-true-p eglot--managed-mode)
         (eglot-server-capable :documentFormattingProvider))
    (eglot-format-buffer))
   ((and (derived-mode-p '(python-mode python-ts-mode))
         (executable-find "ruff"))
    (shell-command-on-region (point-min) (point-max) "ruff format -" (current-buffer) t))
   (t
    (message "No formatting provider available."))))

(with-eval-after-load 'eglot
  (keymap-set eglot-mode-map "C-c l r" #'eglot-rename)
  (keymap-set eglot-mode-map "C-c l a" #'eglot-code-actions)
  (keymap-set eglot-mode-map "C-c l f" #'my/format-buffer)
  (keymap-set eglot-mode-map "C-c l h" #'eldoc))

(provide 'init)
;;; init.el ends here
