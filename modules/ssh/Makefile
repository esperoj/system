.PHONY: ssh ssh-cfg
ssh: sys-pkgs vault stow
	mkdir -p ~/.ssh
	MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
ssh-cfg: sys-pkgs-cfg .WAIT vault-cfg stow-cfg
	@kv append "apt-pkgs" "openssh-client "

