ifndef MOD_RCLONE
MOD_RCLONE := 1

TERMUX_PKGS += rclone

.PHONY: rclone rclone-update rclone-uninstall
rclone: sys-pkgs
	@install-tool rclone gh:rclone/rclone '{OS}-{ARCH}\.zip$$'

# Self-skips when rclone is host-provided (Termux pkg) or already the
# recorded latest (no redownload).
rclone-update:
	@install-tool -u rclone gh:rclone/rclone '{OS}-{ARCH}\.zip$$'

rclone-uninstall:
	@uninstall-tool rclone
endif
