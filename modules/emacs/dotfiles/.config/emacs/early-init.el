;;; early-init.el --- pre-package startup tuning -*- lexical-binding: t; -*-

;; Runs before package.el and before the first frame is drawn. Keep it
;; tiny: the only decisions worth making this early are garbage
;; collection and whether package.el is allowed to activate packages.
;;
;; The high threshold keeps the init load from pausing on every form;
;; init-core.el lowers it again after startup so a long session does not
;; hold 64MB before collecting.

(setq gc-cons-threshold (* 64 1024 1024)
      gc-cons-percentage 0.5)

;; Do not let package.el activate packages behind our back. init.el
;; calls `package-initialize' once (a local read of what is on disk),
;; and only the explicit `my/ensure-packages' command ever touches the
;; network.
(setq package-enable-at-startup nil)

;; Avoid a menu/tool/scroll bar flash before init-core turns them off.
;; In a terminal build some of these modes do not exist.
(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))

;;; early-init.el ends here
