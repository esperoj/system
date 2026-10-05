ifndef MOD_PUBNIX
MOD_PUBNIX := 1

PUBNIX_MODULES := base dev crontab wireproxy stow
$(foreach d,$(PUBNIX_MODULES),$(eval include modules/$d/$d.mk))


VAULT_MODULES += ssh base git rclone


.PHONY: pubnix
pubnix: sys-pkgs $(PUBNIX_MODULES)
	@$(stow-module)
	echo "✓ Pubnix profile applied successfully."
endif
