ifndef MOD_CRONTAB
MOD_CRONTAB := 1

include modules/stow/stow.mk

DEBIAN_PKGS += cron
TERMUX_PKGS += cronie

.PHONY: crontab crontab-uninstall
crontab: sys-pkgs stow
	@$(stow-module)
	crontab "$${HOME}/.config/crontab/crontab"
	@$(mark-applied)

# The module's file replaced the crontab wholesale at install time; the
# uninstall script removes it again, but only while it is still ours.
crontab-uninstall:
	@MODULES_DIR="$(MODULES_DIR)/crontab" dot remove dotfiles
	"$(MODULES_DIR)/crontab/uninstall"
	rm -f "$(STATE_DIR)/modules/crontab"
endif
