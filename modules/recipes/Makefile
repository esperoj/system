.PHONY: recipes recipes-cfg
recipes: stow sys-pkgs
	MODULES_DIR="$(MODULES_DIR)/recipes" dot apply "dotfiles"
recipes-cfg: sys-pkgs-cfg .WAIT stow-cfg
