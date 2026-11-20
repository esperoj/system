ifndef MOD_CHDMAN
MOD_CHDMAN := 1

DEBIAN_PKGS += mame-tools

.PHONY: chdman
chdman: sys-pkgs
	@"$(MODULES_DIR)/chdman/install"
endif
