ifndef MOD_RESTIC
MOD_RESTIC := 1

TERMUX_PKGS += restic

.PHONY: restic restic-update restic-uninstall
restic: sys-pkgs
	@install-tool restic gh:restic/restic '{OS}_{ARCH}\.bz2$$'

restic-update:
	@install-tool -u restic gh:restic/restic '{OS}_{ARCH}\.bz2$$'

restic-uninstall:
	@uninstall-tool restic
endif
