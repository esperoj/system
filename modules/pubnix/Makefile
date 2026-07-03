.PHONY: pubnix pubnix-cfg
PUBNIX_DEPS=base dev crontab wireproxy stow
pubnix: sys-pkgs $(PUBNIX_DEPS)
	MODULES_DIR="$(MODULES_DIR)/pubnix" dot apply dotfiles
pubnix-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(PUBNIX_DEPS))
