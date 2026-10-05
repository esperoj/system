ifndef MOD_ENV
MOD_ENV := 1

include modules/stow/stow.mk

.PHONY: env
env: sys-pkgs stow
	@mkdir -p ~/.config/env
	@MODULES_DIR="$(MODULES_DIR)/env" dot apply dotfiles
endif
