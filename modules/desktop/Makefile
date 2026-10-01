.PHONY: desktop desktop-cfg
DESKTOP_DEPS = stow base dev anki keepassxc firefox emacs crontab wireproxy
desktop: sys-pkgs $(DESKTOP_DEPS)
	MODULES_DIR="$(MODULES_DIR)/desktop" dot apply dotfiles
desktop-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(DESKTOP_DEPS))
	@kv sadd common-pkgs tk tcl
	@kv sadd debian-pkgs bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools
	@kv sadd vault-modules ssh base git rclone
