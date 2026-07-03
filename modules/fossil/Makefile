.PHONY: fossil fossil-cfg
fossil: sys-pkgs
	"$(MODULES_DIR)/fossil/install"
	"$(MODULES_DIR)/fossil/setup"
fossil-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "fossil "

