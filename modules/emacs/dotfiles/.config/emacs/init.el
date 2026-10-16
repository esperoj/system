;;; init.el --- Sovereign, Zero-Lag IDE with Guaranteed Highlighting -*- lexical-binding: t; -*-

;; -----------------------------------------------------------------------------
;; 0. XDG Directories & File Storage
;; -----------------------------------------------------------------------------
(defconst my/state-dir (expand-file-name "emacs/" (or (getenv "XDG_STATE_HOME") "~/.local/state")))
(defconst my/cache-dir (expand-file-name "emacs/" (or (getenv "XDG_CACHE_HOME") "~/.cache")))

(dolist (dir (list my/state-dir
                   my/cache-dir
                   (expand-file-name "backups" my/state-dir)
                   (expand-file-name "auto-save" my/state-dir)))
  (make-directory dir t))

(setq user-emacs-directory my/state-dir
      backup-directory-alist `(("." . ,(expand-file-name "backups" my/state-dir)))
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
;; 1. UI & Performance Tuning (Eliminates All UI Freezes)
;; -----------------------------------------------------------------------------
(setq gc-cons-threshold 100000000
      gc-cons-percentage 0.2
      inhibit-startup-screen t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

;; 1MB IPC buffer prevents stutter when language servers stream output
(setq read-process-output-max (* 1024 1024)
      process-adaptive-read-buffering nil)

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold 67108864)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; -----------------------------------------------------------------------------
;; 2. Guaranteed Syntax Highlighting & Editor Behavior
;; -----------------------------------------------------------------------------
;; Force maximum font-lock decoration across all modes
(global-font-lock-mode 1)
(setq font-lock-maximum-decoration t)
(setq-default font-lock-maximum-decoration t)

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
;; 3. Built-in Completion (TAB Autocomplete + Vertical Minibuffer)
;; -----------------------------------------------------------------------------
;; Built-in code completion via TAB:
;; - Press TAB at indentation: indents code
;; - Press TAB after a dot or word (e.g. `os.`): autocompletes from ty LSP
(setq tab-always-indent 'complete
      completions-detailed t
      completion-auto-select t
      completions-max-height 12)

;; Minibuffer completion (for finding files, switching buffers, M-x)
(icomplete-vertical-mode 1)
(setq icomplete-show-matches-on-no-input t
      completion-styles '(substring flex partial-completion basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion substring flex basic)))
      completions-format 'one-column)

(keymap-set minibuffer-local-completion-map "SPC" #'self-insert-command)

;; -----------------------------------------------------------------------------
;; 4. History, State & Fast Search
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
;; 6. Languages & Optional Tree-sitter
;; -----------------------------------------------------------------------------
;; File associations using Debian packages
(when (require 'yaml-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode)))

(when (require 'markdown-mode nil 'noerror)
  (add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))
  (add-hook 'markdown-mode-hook #'visual-line-mode))

;; Remap to tree-sitter ONLY if the user manually installed the grammar on disk.
;; This prevents broken, colorless buffers.
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
;; 7. Python with .venv and Astral `ty` LSP
;; -----------------------------------------------------------------------------
(require 'eglot)
(add-to-list 'warning-suppress-types '(eglot))

(setq eglot-autoshutdown t
      eglot-events-buffer-size 0
      eldoc-idle-delay 0.2)

;; Register `ty server` with standard LSP language-id "python"
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(((python-mode :language-id "python")
                  (python-ts-mode :language-id "python"))
                 . ("ty" "server"))))

;; Fast O(1) venv detection without mutating global environment
(defun my/find-python-venv ()
  "Find local .venv or venv in project root or current directory."
  (let* ((root (or (when-let* ((proj (project-current)))
                     (project-root proj))
                   default-directory))
         (py-rel (if (eq system-type 'windows-nt) "Scripts/python.exe" "bin/python")))
    (seq-find (lambda (dir)
                (file-executable-p (expand-file-name py-rel dir)))
              (list (expand-file-name ".venv" root)
                    (expand-file-name "venv" root)))))

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

(defun my/python-mode-setup ()
  "Setup Python buffer, activate venv, and connect to ty server."
  (let ((venv (my/python-activate-venv)))
    (if (executable-find "ty")
        ;; Catch errors so a connection issue NEVER breaks syntax highlighting
        (condition-case err
            (eglot-ensure)
          (error (message "Eglot: %s" (error-message-string err))))
      (message "Note: 'ty' not found in %s. Run: (.venv) $ pip install ty"
               (if venv (concat venv "/bin") "local .venv")))))

(add-hook 'python-base-mode-hook #'my/python-mode-setup)
(add-hook 'python-mode-hook #'my/python-mode-setup)

;; Bash LSP
(dolist (hook '(bash-ts-mode-hook sh-mode-hook))
  (add-hook hook
            (lambda ()
              (when (executable-find "bash-language-server")
                (ignore-errors (eglot-ensure))))))

;; JSON LSP
(setq js-indent-level 2)
(dolist (hook '(json-ts-mode-hook js-json-mode-hook))
  (add-hook hook
            (lambda ()
              (when (or (executable-find "vscode-json-language-server")
                        (executable-find "json-languageserver"))
                (ignore-errors (eglot-ensure))))))

;; YAML LSP
(dolist (hook '(yaml-mode-hook yaml-ts-mode-hook))
  (add-hook hook
            (lambda ()
              (when (executable-find "yaml-language-server")
                (ignore-errors (eglot-ensure))))))

;; -----------------------------------------------------------------------------
;; 8. Visuals
;; -----------------------------------------------------------------------------
(load-theme 'modus-vivendi t)

(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Monospace" :height 140))
(add-to-list 'default-frame-alist '(font . "Monospace-14"))

(setq-default line-spacing 0.15)
(column-number-mode 1)
(global-display-line-numbers-mode 1)
;; -----------------------------------------------------------------------------
;; 9. Pragmatic Ergonomic Keybindings
;; -----------------------------------------------------------------------------
;; Git: Launch Magit status
(keymap-global-set "C-x g" #'magit-status)

;; Fast Recent Files via built-in completing-read
(defun my/recentf-open ()
  "Find recent file using built-in completing-read."
  (interactive)
  (find-file (completing-read "Recent file: " recentf-list nil t)))
(keymap-global-set "C-x C-r" #'my/recentf-open)


;; Eglot LSP shortcuts under standard prefix `C-c l`
(with-eval-after-load 'eglot
  (keymap-set eglot-mode-map "C-c l r" #'eglot-rename)
  (keymap-set eglot-mode-map "C-c l a" #'eglot-code-actions)
  (keymap-set eglot-mode-map "C-c l f" #'eglot-format)
  (keymap-set eglot-mode-map "C-c l h" #'eldoc))

;; Fast line commenting (built-in since Emacs 25+)
(keymap-global-set "M-/" #'comment-line)
(provide 'init)
;;; init.el ends here
