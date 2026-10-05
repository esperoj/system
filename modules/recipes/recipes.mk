ifndef MOD_RECIPES
MOD_RECIPES := 1

include modules/stow/stow.mk

.PHONY: recipes
recipes: sys-pkgs stow
	@$(stow-module)
endif
