.PHONY: shell shell-cfg
shell: stow
	MODULES_DIR="$(MODULES_DIR)/shell" dot apply dotfiles
shell-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd common-pkgs bash
