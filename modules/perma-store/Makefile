.PHONY: perma-store perma-store-cfg
perma-store: sys-pkgs stow
	MODULES_DIR="$(MODULES_DIR)/perma-store" dot apply dotfiles
perma-store-cfg: sys-pkgs-cfg .WAIT stow-cfg
