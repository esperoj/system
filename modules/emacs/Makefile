.PHONY: emacs emacs-cfg
emacs: stow sys-pkgs
	mkdir -p ~/.config/emacs
	MODULES_DIR="$(MODULES_DIR)/emacs" dot apply dotfiles
emacs-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "emacs-gtk elpa-markdown-mode elpa-vc-fossil "

