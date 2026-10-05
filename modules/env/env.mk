ifndef MOD_ENV
MOD_ENV := 1

include modules/stow/stow.mk

.PHONY: env
env: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/env" dot apply dotfiles
endif
