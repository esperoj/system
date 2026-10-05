ifndef MOD_RCLONE
MOD_RCLONE := 1

TERMUX_PKGS += rclone

.PHONY: rclone
rclone: sys-pkgs
	@"$(MODULES_DIR)/rclone/install"
endif
