.PHONY: restic restic-cfg
restic: sys-pkgs
	"$(MODULES_DIR)/restic/install"
restic-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "restic "

