ifndef MOD_BIN
MOD_BIN := 1

include modules/stow/stow.mk

.PHONY: bin
bin: sys-pkgs stow
	@$(stow-module)
endif
