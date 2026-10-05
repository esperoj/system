ifndef MOD_LIB
MOD_LIB := 1

include modules/stow/stow.mk

.PHONY: lib
lib: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/lib" dot apply dotfiles
endif
