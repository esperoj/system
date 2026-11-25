ifndef MOD_CRONTAB
MOD_CRONTAB := 1

include modules/stow/stow.mk

DEBIAN_PKGS += cron
TERMUX_PKGS += cronie

.PHONY: crontab
crontab: sys-pkgs stow
	@$(stow-module)
	crontab "$${HOME}/.config/crontab/crontab"
endif
