;;; init-mobile.el --- Termux and Android adjustments -*- lexical-binding: t; -*-

;; Termux Emacs is a terminal build with a different prefix and no
;; system packages. The rest of the configuration already guards every
;; optional feature; this file only fixes the host-specific bits that
;; cannot be discovered from a mode hook.

(require 'subr-x)

(defun my/mobile-p ()
  "Non-nil when running under Termux on Android."
  (or (eq system-type 'android)
      (and (getenv "TERMUX_VERSION") t)
      (and (string-prefix-p "/data/data/com.termux"
                            (or (getenv "HOME") ""))
           t)))

(when (my/mobile-p)
  ;; Termux has no /bin/sh; use the shell Termux actually provides.
  (let ((bash (executable-find "bash")))
    (when bash
      (setq shell-file-name bash
            explicit-shell-file-name bash)))

  ;; The Termux prefix is the system root on a phone.
  (let ((prefix (getenv "PREFIX")))
    (when (and prefix (file-directory-p (expand-file-name "bin" prefix)))
      (add-to-list 'exec-path (expand-file-name "bin" prefix))
      (setenv "PATH" (concat (expand-file-name "bin" prefix)
                             path-separator
                             (or (getenv "PATH") "")))))

  ;; Open URLs with the Android intent helper when it is present.
  (when (executable-find "termux-open-url")
    (setq browse-url-browser-function 'browse-url-generic
          browse-url-generic-program "termux-open-url")))

(provide 'init-mobile)
;;; init-mobile.el ends here
