ifndef MOD_RECIPES
MOD_RECIPES := 1

include modules/stow/stow.mk

.PHONY: recipes recipes-update recipes-uninstall
recipes: sys-pkgs stow
	@$(stow-module)

recipes-update:
	@$(call refresh-module,recipes)

recipes-uninstall:
	@$(call unstow-module,recipes)
endif
