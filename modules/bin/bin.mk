ifndef MOD_BIN
MOD_BIN := 1

include modules/stow/stow.mk

.PHONY: bin bin-update bin-uninstall
bin: sys-pkgs stow
	@$(stow-module)
	"$(MODULES_DIR)/bin/install"

bin-update:
	@$(call refresh-module,bin)
	"$(MODULES_DIR)/bin/install"

bin-uninstall:
	@$(call unstow-module,bin)
	"$(MODULES_DIR)/bin/uninstall"
endif
