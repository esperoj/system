ifndef MOD_PUBNIX
MOD_PUBNIX := 1

include modules/base/base.mk
include modules/dev/dev.mk
include modules/crontab/crontab.mk
include modules/wireproxy/wireproxy.mk
include modules/stow/stow.mk

VAULT_MODULES += ssh base git rclone

PUBNIX_MODULES := base dev crontab wireproxy stow

.PHONY: pubnix
pubnix: sys-pkgs $(PUBNIX_MODULES)
	@MODULES_DIR="$(MODULES_DIR)/pubnix" dot apply dotfiles
	@echo "✓ Pubnix profile applied successfully."
endif
