ifndef MOD_WIREPROXY
MOD_WIREPROXY := 1

include modules/stow/stow.mk

.PHONY: wireproxy
wireproxy: sys-pkgs stow
	@"$(MODULES_DIR)/wireproxy/install"
	$(stow-module)
endif
