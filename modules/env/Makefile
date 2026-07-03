.PHONY: env env-cfg
env: sys-pkgs stow
	mkdir -p ~/.config/env
	MODULES_DIR="$(MODULES_DIR)/env" dot apply dotfiles
env-cfg: sys-pkgs-cfg .WAIT stow-cfg
