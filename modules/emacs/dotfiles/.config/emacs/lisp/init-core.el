;;; init-core.el --- paths, state and clean defaults -*- lexical-binding: t; -*-

;; The foundation: where state lives, what the frame looks like, and
;; the built-in ergonomics every buffer wants. Nothing here loads an
;; optional package; every `require' is a preloaded or trivially cheap
;; built-in.

;; -----------------------------------------------------------------------------
;; 1. Startup memory and process plumbing
;; -----------------------------------------------------------------------------
;; The high GC threshold comes from early-init.el. Reset it after
;; startup so a long session does not hold 64MB before collecting; no
;; idle GC timer, because a five-second collection is exactly the
;; periodic lag this rewrite removes.
(setq read-process-output-max (* 1024 1024))

(if after-init-time
    (setq gc-cons-threshold (* 32 1024 1024)
          gc-cons-percentage 0.1)
  (add-hook 'after-init-hook
            (lambda ()
              (setq gc-cons-threshold (* 32 1024 1024)
                    gc-cons-percentage 0.1)
              (garbage-collect))))

;; -----------------------------------------------------------------------------
;; 2. System PATH
;; -----------------------------------------------------------------------------
(dolist (dir (list (expand-file-name "~/.local/bin")
                   (expand-file-name "~/.cargo/bin")
                   "/usr/local/bin"))
  (when (file-directory-p dir)
    (add-to-list 'exec-path dir)
    (setenv "PATH" (concat dir path-separator (or (getenv "PATH") "")))))

;; -----------------------------------------------------------------------------
;; 3. State files
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
;; 4. UI and message silencing
;; -----------------------------------------------------------------------------
(setq inhibit-startup-screen t
      initial-scratch-message nil
      use-dialog-box nil
      ring-bell-function 'ignore
      scroll-margin 2
      scroll-conservatively 101
      scroll-preserve-screen-position t)

(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;; Silence verbose "Setting up indent for shell type bash" echo-area
;; spam without hiding real errors.
(defun my/suppress-sh-indent-messages (orig-fun &rest args)
  (let ((inhibit-message t)
        (message-log-max nil))
    (apply orig-fun args)))

(with-eval-after-load 'sh-script
  (advice-add 'sh-set-shell :around #'my/suppress-sh-indent-messages)
  (advice-add 'sh-make-vars-local :around #'my/suppress-sh-indent-messages))

;; -----------------------------------------------------------------------------
;; 5. Built-in ergonomics
;; -----------------------------------------------------------------------------
(global-font-lock-mode 1)
(when (fboundp 'repeat-mode) (repeat-mode 1))
(save-place-mode 1)
(winner-mode 1)
(electric-pair-mode 1)
(delete-selection-mode 1)
(show-paren-mode 1)
(setq show-paren-delay 0)

;; Both are built-in from Emacs 30.1; guard so the same init loads on
;; the older Emacs a Termux or pubnix host may still carry.
(when (fboundp 'which-key-mode) (which-key-mode 1))
(when (fboundp 'editorconfig-mode) (editorconfig-mode 1))

;; Non-blocking auto-revert: no polling, no VC subprocess per buffer.
(setq auto-revert-avoid-polling t
      auto-revert-check-vc-info nil
      auto-revert-stop-on-user-input t)
(global-auto-revert-mode 1)

(setq-default indent-tabs-mode nil
              tab-width 4
              fill-column 80)

;; -----------------------------------------------------------------------------
;; 6. History and search
;; -----------------------------------------------------------------------------
(require 'recentf)
(setq recentf-save-file (locate-user-emacs-file "recentf")
      recentf-max-saved-items 200)
(recentf-mode 1)

(setq savehist-file (locate-user-emacs-file "history"))
(savehist-mode 1)

(when (executable-find "rg")
  (setq xref-search-program 'ripgrep))

(provide 'init-core)
;;; init-core.el ends here
