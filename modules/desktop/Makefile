.PHONY: desktop
DESKTOP_DEPS = stow base dev keepassxc firefox emacs crontab wireproxy
desktop: sys-pkgs $(DESKTOP_DEPS)
	MODULES_DIR="$(MODULES_DIR)/desktop" dot apply dotfiles
desktop-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(DESKTOP_DEPS))
	@kv append "apt-pkgs" "bleachbit tk tcl redshift-gtk gvfs-backends gvfs-fuse mtp-tools"
