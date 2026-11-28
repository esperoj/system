;;; init-git.el --- Magit, smerge and VC -*- lexical-binding: t; -*-

;; Magit is optional: Debian ships it as elpa-magit, Termux may not have
;; it at all. The binding points at `my/magit-status', which asks
;; `my/require-package' to load or install it on first use, so a missing
;; package never breaks startup.

(defun my/magit-status (&optional arg)
  "Run `magit-status', installing Magit on first use when it is missing."
  (interactive "P")
  (if (my/require-package 'magit)
      (magit-status arg)
    (user-error "Magit is not installed")))

(with-eval-after-load 'magit
  (setq magit-display-buffer-function
        #'magit-display-buffer-same-window-except-diff-v1))

(defun my/maybe-smerge-mode ()
  "Enable `smerge-mode' cheaply without regex-scanning large files."
  (when (and buffer-file-name
             (bound-and-true-p vc-mode)
             (not (file-remote-p buffer-file-name))
             (< (buffer-size) 500000))
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward "^<<<<<<< " 10000 t)
        (smerge-mode 1)))))

(add-hook 'find-file-hook #'my/maybe-smerge-mode)

(provide 'init-git)
;;; init-git.el ends here
