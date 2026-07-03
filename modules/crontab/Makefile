.PHONY: crontab crontab-cfg
crontab: sys-pkgs stow
	MODULES_DIR="$(MODULES_DIR)/crontab" dot apply dotfiles
	crontab "$${HOME}/.config/crontab/crontab"
crontab-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "cron "

