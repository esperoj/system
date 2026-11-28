;;; init-packages.el --- optional ELPA packages, installed on demand -*- lexical-binding: t; -*-

;; Nothing here runs the network at startup. `package-initialize' only
;; activates what is already on disk; the install commands are
;; interactive, and `my/require-package' calls one only when a command
;; actually needs a package that is missing.

(require 'package nil 'noerror)

(when (featurep 'package)
  (setq package-enable-at-startup nil)
  (package-initialize))

(defgroup my nil
  "Personal Emacs configuration."
  :group 'emacs)

(defcustom my/packages '(magit markdown-mode yaml-mode)
  "Optional packages this configuration knows how to use.

They are installed only by `my/ensure-packages', or on first use of a
command that needs one through `my/require-package'. Never during
startup: a missing package must not break boot on a phone or a pubnix."
  :type '(repeat symbol)
  :group 'my)

(defcustom my/package-auto-install nil
  "When non-nil, `my/ensure-package' installs without prompting.

Leave it nil for a predictable, network-free startup: the first use of
a missing package asks before downloading."
  :type 'boolean
  :group 'my)

(defun my/ensure-package (package)
  "Install PACKAGE from ELPA when it is missing.

This is the only network path in the configuration, and it is never
called during startup. `my/ensure-packages' calls it interactively;
`my/require-package' calls it on first use of a command."
  (interactive
   (list (intern (completing-read "Package: "
                                  (mapcar #'symbol-name my/packages)
                                  nil t))))
  (if (or (featurep package)
          (require package nil 'noerror))
      package
    (when (or my/package-auto-install
              (y-or-n-p (format "Install %s from ELPA? " package)))
      (unless package-archive-contents
        (package-refresh-contents))
      (package-install package)
      package)))

(defun my/ensure-packages ()
  "Install every missing package in `my/packages'."
  (interactive)
  (dolist (package my/packages)
    (if (require package nil 'noerror)
        (message "✓ %s available" package)
      (my/ensure-package package))))

(defun my/require-package (package)
  "Require PACKAGE, installing it on demand when it is missing.

Return PACKAGE on success, or nil when the user declined the install."
  (cond
   ((require package nil 'noerror) package)
   ((my/ensure-package package)
    (when (require package nil 'noerror) package))
   (t nil)))

(provide 'init-packages)
;;; init-packages.el ends here
