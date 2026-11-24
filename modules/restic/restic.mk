ifndef MOD_RESTIC
MOD_RESTIC := 1

TERMUX_PKGS += restic

.PHONY: restic
restic: sys-pkgs
	@install-tool restic gh:restic/restic '{OS}_{ARCH}\.bz2$$'
endif
