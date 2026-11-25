ifndef MOD_RCLONE
MOD_RCLONE := 1

TERMUX_PKGS += rclone

.PHONY: rclone
rclone: sys-pkgs
	@install-tool rclone gh:rclone/rclone '{OS}-{ARCH}\.zip$$'
endif
