.PHONY: ssh ssh-cfg
ssh: sys-pkgs stow
	mkdir -p ~/.ssh
	MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
ssh-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd apk-pkgs openssh
	@kv sadd apt-pkgs openssh-client
