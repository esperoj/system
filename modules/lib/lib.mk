ifndef MOD_LIB
MOD_LIB := 1

include modules/stow/stow.mk

.PHONY: lib lib-update lib-uninstall
lib: sys-pkgs stow
	@$(stow-module)

lib-update:
	@$(call refresh-module,lib)

lib-uninstall:
	@$(call unstow-module,lib)
endif
