.PHONY: age age-cfg
age: sys-pkgs stow
	"$(MODULES_DIR)/age/install"
	mkdir -p ~/.config/age
	MODULES_DIR="$(MODULES_DIR)/age" dot apply dotfiles
age-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "age "

