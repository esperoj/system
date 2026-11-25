ifndef MOD_SSH
MOD_SSH := 1

include modules/stow/stow.mk

DEBIAN_PKGS += openssh-client
ALPINE_PKGS += openssh
TERMUX_PKGS += openssh

.PHONY: ssh ssh-update ssh-uninstall
ssh: sys-pkgs stow
	@$(stow-module)
	chmod 700 ~/.ssh

ssh-update:
	@$(call refresh-module,ssh)

ssh-uninstall:
	@$(call unstow-module,ssh)
endif
