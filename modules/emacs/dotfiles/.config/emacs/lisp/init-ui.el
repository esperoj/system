;;; init-ui.el --- theme, frame and buffer appearance -*- lexical-binding: t; -*-

;; Modus is built-in and loads without a package or a network call.
;; Everything that needs a display is guarded by `display-graphic-p', so
;; the same init loads in a terminal and under Termux.

(load-theme 'modus-vivendi t)

(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Monospace" :height 140)
  (add-to-list 'default-frame-alist '(font . "Monospace-14"))
  (when (fboundp 'pixel-scroll-precision-mode)
    (pixel-scroll-precision-mode 1))
  (when (fboundp 'window-divider-mode)
    (window-divider-mode 1)))

(setq-default line-spacing 0.15)
(column-number-mode 1)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)
(add-hook 'text-mode-hook #'display-line-numbers-mode)

(provide 'init-ui)
;;; init-ui.el ends here
