;;; run-tests.el --- ERT entry point for the Emacs configuration -*- lexical-binding: t; -*-

;; Run from the repository root:
;;   emacs -Q --batch -l tests/emacs/run-tests.el
;; or through `make test` / `make test-emacs'.
;;
;; The suite is hermetic: init.el writes its state into a temporary
;; user-emacs-directory, package.el uses a temporary package-user-dir,
;; and the two package network entry points are advised to fail loudly
;; if anything tries them during startup.

(require 'ert)
(require 'cl-lib)

(defvar my/test-repo-root
  (expand-file-name "../.." (file-name-directory load-file-name)))

(setq user-emacs-directory
      (file-name-as-directory (make-temp-file "system-emacs-test-" t)))
(setq package-user-dir (expand-file-name "elpa" user-emacs-directory))
(setq package-enable-at-startup nil)

(defvar my/test-network-called nil)
(advice-add 'package-refresh-contents :override
            (lambda (&rest _)
              (setq my/test-network-called t)
              (error "network at startup: package-refresh-contents")))
(advice-add 'package-install :override
            (lambda (&rest _)
              (setq my/test-network-called t)
              (error "network at startup: package-install")))

(load (expand-file-name "modules/emacs/dotfiles/.config/emacs/init.el"
                        my/test-repo-root)
      nil t)

(add-hook 'kill-emacs-hook
          (lambda ()
            (ignore-errors (delete-directory user-emacs-directory t))))

;; -----------------------------------------------------------------------------
;; Startup contract
;; -----------------------------------------------------------------------------
(ert-deftest init-loads-without-network ()
  (should-not my/test-network-called)
  (should (featurep 'init)))

(ert-deftest init-is-a-thin-loader ()
  (let* ((file (expand-file-name
                "modules/emacs/dotfiles/.config/emacs/init.el"
                my/test-repo-root))
         (source (with-temp-buffer
                   (insert-file-contents file)
                   (buffer-string))))
    (should (< (length (split-string source "\n")) 80))
    (should-not (string-match-p "(package-install" source))
    (should-not (string-match-p "(package-refresh-contents" source))
    (should-not (string-match-p "(load-theme" source))
    (should (string-match-p "(require 'init-core)" source))))

(ert-deftest modules-are-features ()
  (dolist (feature '(init-core init-editing init-completion init-navigation
                     init-folding init-ui init-git init-lang init-packages
                     init-mobile init-keybindings))
    (should (featurep feature))))

(ert-deftest optional-packages-stay-unloaded ()
  (dolist (feature '(magit markdown-mode yaml-mode eglot))
    (should-not (featurep feature))))

(ert-deftest state-files-are-hermetic ()
  (should (string-prefix-p user-emacs-directory custom-file))
  (should (string-prefix-p user-emacs-directory recentf-save-file))
  (should (string-prefix-p user-emacs-directory savehist-file)))

;; -----------------------------------------------------------------------------
;; Keybindings and command surfaces
;; -----------------------------------------------------------------------------
(ert-deftest global-keybindings ()
  (should (eq (keymap-lookup global-map "C-x g") 'my/magit-status))
  (should (eq (keymap-lookup global-map "C-x C-r") 'my/recentf-open))
  (should (eq (keymap-lookup global-map "M-/") 'hippie-expand))
  (should (eq (keymap-lookup global-map "C-;") 'comment-line))
  (should (eq (keymap-lookup global-map "C-c b") 'my/alternate-buffer))
  (should (eq (keymap-lookup global-map "C-c i") 'imenu))
  (should (eq (keymap-lookup global-map "C-c C-=") 'my/format-buffer))
  (should (eq (keymap-lookup global-map "C-c C-\\") 'my/indent-buffer))
  (should (eq (keymap-lookup global-map "C-c C-<left>") 'winner-undo))
  (should (eq (keymap-lookup global-map "C-c C-<right>") 'winner-redo)))

(ert-deftest navigation-prefix ()
  (let ((map (keymap-lookup global-map "C-c t")))
    (should (keymapp map))
    (dolist (binding '(("n" . my/treesit-next-defun)
                       ("p" . my/treesit-prev-defun)
                       ("f" . my/treesit-forward-sexp)
                       ("b" . my/treesit-backward-sexp)
                       ("u" . my/treesit-up-list)
                       ("d" . my/treesit-down-list)
                       ("a" . my/treesit-beginning-of-defun)
                       ("e" . my/treesit-end-of-defun)
                       ("i" . my/treesit-inspect)
                       ("x" . my/treesit-explore)))
      (should (eq (keymap-lookup map (car binding)) (cdr binding))))))

(ert-deftest folding-prefix ()
  (let ((map (keymap-lookup global-map "C-c f")))
    (should (keymapp map))
    (dolist (binding '(("f" . my/toggle-fold)
                       ("h" . my/hide-all)
                       ("s" . my/show-all)
                       ("c" . my/toggle-comment-fold)
                       ("t" . my/toggle-top-level)
                       ("l" . my/hide-levels)
                       ("o" . my/toggle-outline)))
      (should (eq (keymap-lookup map (car binding)) (cdr binding))))))

(ert-deftest commands-are-interactive ()
  (dolist (command '(my/magit-status my/recentf-open my/alternate-buffer
                     my/treesit-next-defun my/treesit-prev-defun
                     my/treesit-forward-sexp my/treesit-backward-sexp
                     my/treesit-up-list my/treesit-down-list
                     my/treesit-beginning-of-defun my/treesit-end-of-defun
                     my/treesit-inspect my/treesit-explore
                     my/toggle-fold my/hide-all my/show-all
                     my/toggle-comment-fold my/toggle-top-level
                     my/hide-levels my/toggle-outline
                     my/format-buffer my/indent-buffer
                     my/ensure-packages my/ensure-package))
    (should (commandp command))))

;; -----------------------------------------------------------------------------
;; Behaviour
;; -----------------------------------------------------------------------------
(ert-deftest python-venv-discovery ()
  (let* ((dir (make-temp-file "system-venv-" t))
         (venv (expand-file-name ".venv" dir))
         (bin (expand-file-name "bin" venv))
         (python (expand-file-name "python" bin)))
    (mkdir bin t)
    (with-temp-file python (insert "#!/bin/sh\n"))
    (set-file-modes python #o755)
    (unwind-protect
        (let ((default-directory dir))
          (should (string= (my/find-python-venv) venv)))
      (delete-directory dir t))))

(ert-deftest python-lsp-command-prefers-ty ()
  (cl-letf (((symbol-function 'executable-find)
             (lambda (name &optional _remote) (string= name "ty"))))
    (should (equal (my/python-lsp-command) '("ty" "server")))))

(ert-deftest ensure-package-reuses-a-loaded-feature ()
  (should (eq (my/ensure-package 'seq) 'seq))
  (should-not my/test-network-called))

(ert-deftest ensure-package-asks-before-installing ()
  (cl-letf (((symbol-function 'y-or-n-p) (lambda (&rest _) nil))
            ((symbol-function 'package-refresh-contents)
             (lambda () (setq my/test-network-called t)))
            ((symbol-function 'package-install)
             (lambda (&rest _) (setq my/test-network-called t))))
    (should-not (my/ensure-package 'system-definitely-missing-package))
    (should-not my/test-network-called)))

(ert-deftest folding-command-enables-a-fold-engine ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun my/test-fn ()\n  (+ 1 2))\n")
    (goto-char (point-min))
    (my/toggle-fold)
    (should (or (bound-and-true-p hs-minor-mode)
                (bound-and-true-p outline-minor-mode)))))

(ert-deftest treesit-command-falls-back-outside-a-ts-buffer ()
  (with-temp-buffer
    (emacs-lisp-mode)
    (insert "(defun my/test-fn () 1)\n")
    (goto-char (point-min))
    (my/treesit-forward-sexp)
    (should (> (point) 1))))

(ert-deftest treesit-install-command-is-interactive ()
  (when (and (fboundp 'treesit-available-p) (treesit-available-p))
    (should (commandp 'my/treesit-install-grammars))))

(ert-deftest mobile-detection-is-safe ()
  (should (memq (my/mobile-p) '(t nil))))

;; -----------------------------------------------------------------------------
;; Static guarantees
;; -----------------------------------------------------------------------------
(ert-deftest no-idle-gc-timer-is-installed ()
  (let ((file (expand-file-name
               "modules/emacs/dotfiles/.config/emacs/lisp/init-core.el"
               my/test-repo-root)))
    (with-temp-buffer
      (insert-file-contents file)
      (should-not (string-match-p "run-with-idle-timer" (buffer-string))))))

(ert-deftest init-does-not-require-optional-packages ()
  (let ((file (expand-file-name
               "modules/emacs/dotfiles/.config/emacs/init.el"
               my/test-repo-root)))
    (with-temp-buffer
      (insert-file-contents file)
      (should-not (string-match-p
                   "(require '\\(magit\\|markdown-mode\\|yaml-mode\\|eglot\\))"
                   (buffer-string))))))

(ert-deftest early-init-defers-package-activation ()
  (let ((user-emacs-directory
         (file-name-as-directory (make-temp-file "system-early-init-" t))))
    (unwind-protect
        (progn
          (load (expand-file-name
                 "modules/emacs/dotfiles/.config/emacs/early-init.el"
                 my/test-repo-root)
                nil t)
          (should-not package-enable-at-startup)
          (should (>= gc-cons-threshold (* 64 1024 1024))))
      (delete-directory user-emacs-directory t))))

(ert-deftest every-lisp-file-provides-its-feature ()
  (let ((lisp-dir (expand-file-name
                   "modules/emacs/dotfiles/.config/emacs/lisp"
                   my/test-repo-root)))
    (dolist (file (directory-files lisp-dir t "\\.el\\'"))
      (with-temp-buffer
        (insert-file-contents file)
        (should (string-match-p "^(provide 'init-" (buffer-string)))))))

(ert-deftest every-elisp-file-is-paren-clean ()
  (let ((dirs (list (expand-file-name
                     "modules/emacs/dotfiles/.config/emacs"
                     my/test-repo-root)
                    (expand-file-name
                     "modules/emacs/dotfiles/.config/emacs/lisp"
                     my/test-repo-root))))
    (dolist (dir dirs)
      (dolist (file (directory-files dir t "\\.el\\'"))
        (with-temp-buffer
          (insert-file-contents file)
          (check-parens))))))

(ert-run-tests-batch-and-exit t)
