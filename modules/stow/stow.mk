ifndef MOD_STOW
MOD_STOW := 1

COMMON_PKGS += stow

.PHONY: stow
stow: sys-pkgs
	@"$(MODULES_DIR)/stow/install"
endif
