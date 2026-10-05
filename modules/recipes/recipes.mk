ifndef MOD_RECIPES
MOD_RECIPES := 1

include modules/stow/stow.mk

.PHONY: recipes
recipes: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/recipes" dot apply dotfiles
endif
