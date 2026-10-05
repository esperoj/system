ifndef MOD_BIN
MOD_BIN := 1

include modules/stow/stow.mk

.PHONY: bin
bin: sys-pkgs stow
	@mkdir -p ~/.local/bin
	@MODULES_DIR="$(MODULES_DIR)/bin" dot apply dotfiles
endif
