ifndef MOD_ENV
MOD_ENV := 1

include modules/stow/stow.mk

.PHONY: env
env: sys-pkgs stow
	@$(stow-module)
endif
