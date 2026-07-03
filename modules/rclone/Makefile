.PHONY: rclone rclone-cfg
rclone: sys-pkgs
	"$(MODULES_DIR)/rclone/install"
rclone-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "rclone "

