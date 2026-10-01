.PHONY: xclip xclip-cfg
xclip: stow sys-pkgs
	MODULES_DIR="$(MODULES_DIR)/xclip" dot apply dotfiles
xclip-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd apt-pkgs xclip

