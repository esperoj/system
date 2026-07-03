.PHONY: lib lib-cfg
lib: stow sys-pkgs
	MODULES_DIR="$(MODULES_DIR)/lib" dot apply "dotfiles"
lib-cfg: sys-pkgs-cfg .WAIT stow-cfg
