ifndef MOD_RCLONE
MOD_RCLONE := 1

TERMUX_PKGS += rclone

.PHONY: rclone rclone-update
rclone: sys-pkgs
	@install-tool rclone gh:rclone/rclone '{OS}-{ARCH}\.zip$$'
	@$(mark-applied)

rclone-update: rclone
	@install-tool --update rclone gh:rclone/rclone '{OS}-{ARCH}\.zip$$'
endif
