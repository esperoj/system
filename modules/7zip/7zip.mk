ifndef MOD_7ZIP
MOD_7ZIP := 1

DEBIAN_PKGS += 7zip
TERMUX_PKGS += p7zip

.PHONY: 7zip
7zip: sys-pkgs
	@"$(MODULES_DIR)/7zip/install"
endif
