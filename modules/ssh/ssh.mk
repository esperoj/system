ifndef MOD_SSH
MOD_SSH := 1

include modules/stow/stow.mk

DEBIAN_PKGS += openssh-client
ALPINE_PKGS += openssh
TERMUX_PKGS += openssh

.PHONY: ssh
ssh: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
	chmod 700 ~/.ssh
endif
