;;; init.el --- Sovereign, Portable IDE for Perma Projects -*- lexical-binding: t; -*-

;; Forward declarations
(defvar tramp-persistency-file-name)
(defvar url-configuration-directory)
(defvar treesit-language-source-alist)
(defvar major-mode-remap-alist)
(defvar icomplete-show-matches-on-no-input)
(defvar icomplete-hide-common-prefix)
(defvar savehist-file)
(defvar markdown-command)

;; 0. XDG Directories
(defconst xdg-state-home (or (getenv "XDG_STATE_HOME") "~/.local/state"))
(defconst xdg-cache-home (or (getenv "XDG_CACHE_HOME") "~/.cache"))
(defconst xdg-data-home  (or (getenv "XDG_DATA_HOME")  "~/.local/share"))

(defconst my/state-dir (expand-file-name "emacs/" xdg-state-home))
(defconst my/cache-dir (expand-file-name "emacs/" xdg-cache-home))
(defconst my/data-dir  (expand-file-name "emacs/" xdg-data-home))

(dolist (dir (list my/state-dir
                   my/cache-dir
                   my/data-dir
                   (expand-file-name "backups" my/state-dir)
                   (expand-file-name "auto-save" my/state-dir)))
  (make-directory dir t))

(setq user-emacs-directory my/state-dir
      package-user-dir (expand-file-name "elpa" my/state-dir)
      backup-directory-alist `(("." . ,(expand-file-name "backups" my/state-dir)))
      auto-save-file-name-transforms `((".*" ,(expand-file-name "auto-save" my/state-dir) t))
      create-lockfiles nil
      custom-file (expand-file-name "custom.el" my/state-dir)
      tramp-persistency-file-name (expand-file-name "tramp" my/cache-dir)
      url-configuration-directory (expand-file-name "url/" my/cache-dir))

(when (boundp 'native-comp-eln-load-path)
  (add-to-list 'native-comp-eln-load-path
               (expand-file-name "eln-cache/" my/cache-dir)))

(when (file-exists-p custom-file)
  (load custom-file 'noerror 'nomessage))

;; 1. UI & Performance
(setq gc-cons-threshold 100000000
      inhibit-startup-screen t
      inhibit-startup-message t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore)

(add-hook 'emacs-startup-hook
          (lambda () (setq gc-cons-threshold 800000)))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

;; 2. Built-in Ergonomics
(when (fboundp 'pixel-scroll-precision-mode)
  (pixel-scroll-precision-mode 1))

(global-auto-revert-mode 1)
(save-place-mode 1)
(savehist-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)

(when (fboundp 'repeat-mode)
  (repeat-mode 1))

(setq-default indent-tabs-mode nil)

;; 3. Package Management
(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))

(package-initialize)

(defun my/ensure-packages (pkgs)
  "Ensure PKGS are available, installing them best-effort.
Startup is not interrupted if package archives are unreachable."
  (let ((to-install nil))
    (dolist (pkg pkgs)
      (unless (or (package-installed-p pkg)
                  (require pkg nil 'noerror))
        (push pkg to-install)))

    (when to-install
      (ignore-errors
        (unless package-archive-contents
          (package-refresh-contents))

        (dolist (pkg to-install)
          (package-install pkg))

        (dolist (pkg to-install)
          (require pkg nil 'noerror))))))

(my/ensure-packages '(magit markdown-mode yaml-mode treesit-auto))

;; 4. Completion (Icomplete + Flex)
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

;; 5. Recent Files & Projects
(require 'recentf)

(setq recentf-save-file (expand-file-name "recentf" my/state-dir)
      recentf-max-saved-items 200)

(recentf-mode 1)

(setq savehist-file (expand-file-name "history" my/state-dir))
(savehist-mode 1)

(require 'project)
(setq project-list-file (expand-file-name "projects" my/state-dir))

;; 6. Git / Magit
(with-eval-after-load 'magit
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1))

(defun my/maybe-smerge-mode ()
  "Enable `smerge-mode' only for likely conflict files."
  (when (and buffer-file-name
             (not (file-remote-p buffer-file-name))
             (< (buffer-size) 2000000))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " nil t)
        (smerge-mode 1)))))

(add-hook 'find-file-hook #'my/maybe-smerge-mode)

;; 7. Tree-sitter & Mappings
(defconst my/treesit-languages
  '((bash "https://github.com/tree-sitter/tree-sitter-bash" "v0.20.0")
    (python "https://github.com/tree-sitter/tree-sitter-python" "v0.20.4")
    (json "https://github.com/tree-sitter/tree-sitter-json" "v0.20.2")
    (yaml "https://github.com/ikatyang/tree-sitter-yaml")
    (toml "https://github.com/tree-sitter/tree-sitter-toml" "v0.20.0")))

(when (and (fboundp 'treesit-available-p)
           (treesit-available-p))
  (if (require 'treesit-auto nil 'noerror)
      (global-treesit-auto-mode 1)
    (setq treesit-language-source-alist my/treesit-languages)

    (dolist (mapping '((bash . sh-mode)
                       (python . python-mode)
                       (json . js-json-mode)
                       (yaml . yaml-mode)))
      (when (treesit-language-available-p (car mapping))
        (add-to-list 'major-mode-remap-alist
                     (cons (cdr mapping)
                           (intern (format "%s-ts-mode" (car mapping)))))))))

(when (locate-library "yaml-mode")
  (add-to-list 'auto-mode-alist '("\\.ya?ml\\'" . yaml-mode)))

(add-to-list 'auto-mode-alist '("\\.toml\\'" . conf-toml-mode))

;; 8. Workflows (Python, Bash, JSON, Markdown)
(require 'eglot)
(add-to-list 'warning-suppress-types '(eglot))

(defun my/env-without (env prefix)
  "Return ENV list without entries starting with PREFIX."
  (let ((result '()))
    (dolist (entry env (nreverse result))
      (unless (string-prefix-p prefix entry)
        (push entry result)))))

(defun my/eglot-ensure-if-any (&rest executables)
  "Enable Eglot only when at least one EXECUTABLES exists."
  (catch 'found
    (dolist (exe executables)
      (when (executable-find exe)
        (eglot-ensure)
        (throw 'found t)))))

;; Python: Auto venv detection + Eglot
(defun my/python-activate-venv ()
  "Activate local Python venv for current buffer only."
  (let ((root (if-let* ((proj (project-current)))
                  (project-root proj)
                default-directory)))
    (when-let* ((venv-dir (car (directory-files root t "^\\.?venv$" t)))
                (bin-dir (expand-file-name "bin" venv-dir))
                (python-bin (expand-file-name "python" bin-dir)))
      (when (file-executable-p python-bin)
        (let* ((old-path (or (getenv "PATH" process-environment) ""))
               (clean-env (my/env-without
                           (my/env-without process-environment "VIRTUAL_ENV=")
                           "PATH=")))
          (setq-local process-environment
                      (append
                       (list
                        (format "VIRTUAL_ENV=%s" venv-dir)
                        (format "PATH=%s%s%s"
                                bin-dir
                                path-separator
                                old-path))
                       clean-env))

          (setq-local exec-path
                      (cons bin-dir
                            (seq-filter
                             (lambda (p) (not (equal p bin-dir)))
                             exec-path)))

          (when (boundp 'python-shell-interpreter)
            (setq-local python-shell-interpreter python-bin))

          (message "Activated venv: %s" venv-dir))))))

(add-hook 'python-base-mode-hook #'my/python-activate-venv)
(add-hook 'python-base-mode-hook
          (lambda ()
            (my/eglot-ensure-if-any "pyright" "pyright-langserver")))

;; Bash
(dolist (hook '(bash-ts-mode-hook sh-mode-hook))
  (add-hook hook
            (lambda ()
              (my/eglot-ensure-if-any "bash-language-server"))))

;; JSON
(dolist (hook '(json-ts-mode-hook js-json-mode-hook))
  (add-hook hook
            (lambda ()
              (my/eglot-ensure-if-any "vscode-json-language-server"
                                      "json-languageserver"))))

;; YAML
(add-hook 'yaml-mode-hook
          (lambda ()
            (my/eglot-ensure-if-any "yaml-language-server")))

(setq js-indent-level 2)

;; Markdown
(setq markdown-command "pandoc -f markdown -t html --standalone"
      markdown-header-scaling t)

(when (locate-library "markdown-mode")
  (add-to-list 'auto-mode-alist '("\\.\\(?:md\\|markdown\\)\\'" . markdown-mode))
  (add-to-list 'auto-mode-alist '("README\\.md\\'" . gfm-mode))
  (add-hook 'markdown-mode-hook #'visual-line-mode))

;; 9. Visuals & Keybindings
(load-theme 'modus-vivendi t)

(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Monospace" :height 140))

(setq-default line-spacing 0.15)

(column-number-mode 1)

(when (fboundp 'global-display-line-numbers-mode)
  (global-display-line-numbers-mode 1))

(keymap-global-set "C-x g"   #'magit-status)
(keymap-global-set "C-c r"   #'recentf-open-files)
(keymap-global-set "C-x C-b" #'ibuffer)
(keymap-global-set "M-o"     #'other-window)
(keymap-global-set "C-c p p" #'project-switch-project)
(keymap-global-set "C-c p f" #'project-find-file)
(keymap-global-set "C-c o"   #'imenu)

(provide 'init)
;;; init.el ends here
