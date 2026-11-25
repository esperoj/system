ifndef MOD_CHDMAN
MOD_CHDMAN := 1

DEBIAN_PKGS += mame-tools

.PHONY: chdman chdman-update chdman-uninstall
chdman: sys-pkgs
	@"$(MODULES_DIR)/chdman/install"

chdman-update:
	@"$(MODULES_DIR)/chdman/install" update

chdman-uninstall:
	@"$(MODULES_DIR)/chdman/install" uninstall
endif
