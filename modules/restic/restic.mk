ifndef MOD_RESTIC
MOD_RESTIC := 1

TERMUX_PKGS += restic

.PHONY: restic
restic: sys-pkgs
	@"$(MODULES_DIR)/restic/install"
endif
