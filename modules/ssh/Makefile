.PHONY: ssh ssh-cfg
ssh: sys-pkgs stow
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
ssh-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd debian-pkgs openssh-client
	@kv sadd alpine-pkgs openssh
	@kv sadd termux-pkgs openssh
