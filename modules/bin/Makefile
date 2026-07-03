.PHONY: bin bin-cfg
bin: sys-pkgs stow
	mkdir -p ~/.local/bin
	MODULES_DIR="$(MODULES_DIR)/bin" dot apply dotfiles
bin-cfg: sys-pkgs-cfg .WAIT stow-cfg
