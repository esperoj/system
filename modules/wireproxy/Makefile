.PHONY: wireproxy wireproxy-cfg
wireproxy: stow sys-pkgs
	"$(MODULES_DIR)/wireproxy/install"
	MODULES_DIR="$(MODULES_DIR)/wireproxy" dot apply dotfiles
wireproxy-cfg: sys-pkgs-cfg .WAIT stow-cfg
