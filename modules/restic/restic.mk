ifndef MOD_RESTIC
MOD_RESTIC := 1

TERMUX_PKGS += restic

.PHONY: restic restic-update
restic: sys-pkgs
	@install-tool restic gh:restic/restic '{OS}_{ARCH}\.bz2$$'
	@completion restic
	@$(mark-applied)

restic-update: restic
	@install-tool --update restic gh:restic/restic '{OS}_{ARCH}\.bz2$$'
endif
