ifndef MOD_BIN
MOD_BIN := 1

include modules/stow/stow.mk

.PHONY: bin bin-uninstall
bin: sys-pkgs stow
	@$(stow-module)
	"$(MODULES_DIR)/bin/install"
	@$(mark-applied)

bin-uninstall:
	@MODULES_DIR="$(MODULES_DIR)/bin" dot remove dotfiles
	"$(MODULES_DIR)/bin/uninstall"
	rm -f "$(STATE_DIR)/modules/bin"
endif
