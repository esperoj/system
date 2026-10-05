ifndef MOD_CRONTAB
MOD_CRONTAB := 1

include modules/stow/stow.mk

DEBIAN_PKGS += cron
TERMUX_PKGS += cronie

.PHONY: crontab
crontab: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/crontab" dot apply dotfiles
	@crontab "$${HOME}/.config/crontab/crontab"
endif
