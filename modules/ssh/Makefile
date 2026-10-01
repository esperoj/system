.PHONY: ssh ssh-cfg
ssh: sys-pkgs vault stow
	mkdir -p ~/.ssh
	MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
ssh-cfg: sys-pkgs-cfg .WAIT vault-cfg stow-cfg
	if [ "$$(uname -o 2>/dev/null)" = "Android" ] || [ -n "$$TERMUX_VERSION" ]; then
	  kv sadd apt-pkgs openssh
	else
	  kv sadd apt-pkgs openssh-client
	fi
