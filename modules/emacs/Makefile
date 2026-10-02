.PHONY: emacs emacs-cfg
emacs: stow sys-pkgs
	mkdir -p ~/.config/emacs
	MODULES_DIR="$(MODULES_DIR)/emacs" dot apply dotfiles
emacs-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd common-pkgs pandoc
	@kv sadd debian-pkgs emacs-gtk elpa-markdown-mode elpa-magit elpa-yaml-mode elpa-treesit-auto
	@kv sadd termux-pkgs emacs
