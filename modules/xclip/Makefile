.PHONY: xclip xclip-cfg
xclip: stow sys-pkgs
	dot apply "$(MODULES_DIR)/xclip/dotfiles"
xclip-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "xclip "

