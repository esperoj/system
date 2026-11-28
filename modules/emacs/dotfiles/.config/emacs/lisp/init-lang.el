;;; init-lang.el --- tree-sitter, languages and Eglot -*- lexical-binding: t; -*-

;; Optional ELPA modes are wired only when their autoloads exist. A
;; Termux Emacs without elpa-* packages simply uses the built-in modes,
;; and `my/ensure-packages' can add the rest on demand. Nothing here
;; downloads a grammar or a package at startup: `my/treesit-install-
;; grammars' is an explicit command.

(require 'seq)
(require 'subr-x)

;; -----------------------------------------------------------------------------
;; Optional language modes
;; -----------------------------------------------------------------------------
(when (fboundp 'yaml-mode)
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode))
  (add-hook 'yaml-mode-hook #'my/yaml-eglot-ensure))

(when (fboundp 'markdown-mode)
  (add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . markdown-mode))
  (when (fboundp 'gfm-mode)
    (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode)))
  (add-hook 'markdown-mode-hook #'visual-line-mode))

;; -----------------------------------------------------------------------------
;; Tree-sitter
;; -----------------------------------------------------------------------------
(when (and (fboundp 'treesit-available-p) (treesit-available-p))
  (require 'treesit)
  ;; Level 3 gives full syntax colours without the typing latency of
  ;; level 4. The variable exists from Emacs 29; guard the set anyway.
  (when (boundp 'treesit-font-lock-level)
    (setq treesit-font-lock-level 3))

  (setq treesit-language-source-alist
        '((bash   "https://github.com/tree-sitter/tree-sitter-bash")
          (python "https://github.com/tree-sitter/tree-sitter-python")
          (json   "https://github.com/tree-sitter/tree-sitter-json")
          (yaml   "https://github.com/tree-sitter/tree-sitter-yaml")))

  (defun my/treesit-install-grammars ()
    "Install missing configured Tree-sitter grammars."
    (interactive)
    (dolist (source treesit-language-source-alist)
      (let ((lang (car source)))
        (unless (treesit-language-available-p lang)
          (treesit-install-language-grammar lang)))))

  ;; Remap a mode only when its grammar is actually present, so a
  ;; missing grammar falls back to the native mode instead of warning
  ;; on every file.
  (dolist (mapping '((bash   sh-mode      bash-ts-mode)
                     (python python-mode  python-ts-mode)
                     (json   js-json-mode json-ts-mode)
                     (yaml   yaml-mode    yaml-ts-mode)))
    (when (and (fboundp (nth 2 mapping))
               (treesit-language-available-p (nth 0 mapping)))
      (add-to-list 'major-mode-remap-alist
                   (cons (nth 1 mapping) (nth 2 mapping))))))

;; -----------------------------------------------------------------------------
;; Python: venv discovery and Eglot
;; -----------------------------------------------------------------------------
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
  "Activate local Python venv for the current buffer safely."
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
  "Pick the first Python language server this host provides."
  (cond
   ((executable-find "ty") '("ty" "server"))
   ((executable-find "basedpyright-langserver") '("basedpyright-langserver" "--stdio"))
   ((executable-find "pyright-langserver") '("pyright-langserver" "--stdio"))
   ((executable-find "pylsp") '("pylsp"))
   ((executable-find "ruff") '("ruff" "server"))
   (t nil)))

;; Eglot and Flymake performance: never block the UI on a connection,
;; never log JSON-RPC traffic, debounce eldoc and linting.
(setq eglot-autoshutdown t
      eglot-sync-connect nil
      eglot-events-buffer-size 0
      eldoc-idle-delay 0.5
      eldoc-echo-area-use-multiline-p nil
      flymake-no-changes-timeout 0.5)

(with-eval-after-load 'eglot
  (add-to-list 'warning-suppress-types '(eglot))
  (fset #'jsonrpc--log-event #'ignore)
  (add-to-list 'eglot-server-programs
               `(((python-mode :language-id "python")
                  (python-ts-mode :language-id "python"))
                 . ,(lambda (&optional _interactive _project)
                      (or (my/python-lsp-command) '("ty" "server"))))))

(defun my/python-mode-setup ()
  "Activate the local venv and start Eglot when a server exists."
  (my/python-activate-venv)
  (when (and (my/python-lsp-command) (require 'eglot nil 'noerror))
    (condition-case err
        (eglot-ensure)
      (error (message "Eglot: %s" (error-message-string err))))))

(add-hook 'python-mode-hook #'my/python-mode-setup)
(add-hook 'python-ts-mode-hook #'my/python-mode-setup)

;; -----------------------------------------------------------------------------
;; Secondary language hooks
;; -----------------------------------------------------------------------------
(defun my/bash-eglot-ensure ()
  (when (executable-find "bash-language-server")
    (ignore-errors (eglot-ensure))))
(add-hook 'sh-mode-hook #'my/bash-eglot-ensure)
(when (fboundp 'bash-ts-mode)
  (add-hook 'bash-ts-mode-hook #'my/bash-eglot-ensure))

(setq js-indent-level 2)

(defun my/json-eglot-ensure ()
  (when (or (executable-find "vscode-json-language-server")
            (executable-find "json-languageserver"))
    (ignore-errors (eglot-ensure))))
(when (fboundp 'json-ts-mode)
  (add-hook 'json-ts-mode-hook #'my/json-eglot-ensure))
(add-hook 'js-json-mode-hook #'my/json-eglot-ensure)

(defun my/yaml-eglot-ensure ()
  (when (executable-find "yaml-language-server")
    (ignore-errors (eglot-ensure))))
(when (fboundp 'yaml-ts-mode)
  (add-hook 'yaml-ts-mode-hook #'my/yaml-eglot-ensure))

;; -----------------------------------------------------------------------------
;; Project and formatting
;; -----------------------------------------------------------------------------
(with-eval-after-load 'project
  (setq project-vc-extra-root-markers
        '("pyproject.toml" "setup.py" "requirements.txt" ".venv")))

(defun my/format-buffer ()
  "Format the current buffer through Eglot, or ruff for Python."
  (interactive)
  (cond
   ((and (bound-and-true-p eglot--managed-mode)
         (fboundp 'eglot-server-capable)
         (eglot-server-capable :documentFormattingProvider))
    (eglot-format-buffer))
   ((and (derived-mode-p '(python-mode python-ts-mode))
         (executable-find "ruff"))
    (shell-command-on-region (point-min) (point-max) "ruff format -"
                             (current-buffer) t))
   (t
    (message "No formatting provider available."))))

(with-eval-after-load 'eglot
  (keymap-set eglot-mode-map "C-c l r" #'eglot-rename)
  (keymap-set eglot-mode-map "C-c l a" #'eglot-code-actions)
  (keymap-set eglot-mode-map "C-c l f" #'my/format-buffer)
  (keymap-set eglot-mode-map "C-c l h" #'eldoc))

(provide 'init-lang)
;;; init-lang.el ends here
