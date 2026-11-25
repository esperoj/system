ifndef MOD_PUBNIX
MOD_PUBNIX := 1

PUBNIX_MODULES := base dev crontab wireproxy
$(foreach d,$(PUBNIX_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: pubnix pubnix-update pubnix-uninstall
pubnix: sys-pkgs $(PUBNIX_MODULES)
	@$(stow-module)
	echo "✓ Pubnix profile applied successfully."

pubnix-update: $(PUBNIX_MODULES:%=%-update)
	@$(call refresh-module,pubnix)

# Members uninstall in reverse install order through one serial recursive
# make; base (which owns stow, vault and the CLIs) goes last and orders
# its own members likewise.
pubnix-uninstall:
	@$(MAKE) --no-print-directory -j1 $(strip $(call reverse,$(PUBNIX_MODULES:%=%-uninstall)))
	$(call unstow-module,pubnix)
endif
