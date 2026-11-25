ifndef MOD_SHELL
MOD_SHELL := 1

include modules/stow/stow.mk

COMMON_PKGS += bash

.PHONY: shell
shell: sys-pkgs stow
	@$(stow-module)
endif
