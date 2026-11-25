ifndef MOD_CHDMAN
MOD_CHDMAN := 1

DEBIAN_PKGS += mame-tools

.PHONY: chdman chdman-update chdman-uninstall
chdman: sys-pkgs
	@"$(MODULES_DIR)/chdman/install"
	@$(mark-applied)

chdman-update: chdman
	@"$(MODULES_DIR)/chdman/install" --update

chdman-uninstall:
	@"$(MODULES_DIR)/chdman/uninstall"
	rm -f "$(STATE_DIR)/modules/chdman"
endif
