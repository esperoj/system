ifndef MOD_PUBNIX
MOD_PUBNIX := 1

PUBNIX_MODULES := base dev crontab wireproxy
$(foreach d,$(PUBNIX_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: pubnix
pubnix: sys-pkgs $(PUBNIX_MODULES)
	@$(stow-module)
	echo "✓ Pubnix profile applied successfully."
endif
