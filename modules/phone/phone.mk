ifndef MOD_PHONE
MOD_PHONE := 1

PHONE_MODULES := base restic
$(foreach d,$(PHONE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: phone phone-update phone-uninstall
phone: sys-pkgs $(PHONE_MODULES)
	@$(stow-module)
	echo "✓ Phone profile applied successfully."

phone-update: $(PHONE_MODULES:%=%-update)
	@$(call refresh-module,phone)

# Members uninstall in reverse install order through one serial recursive
# make; base (which owns stow, vault and the CLIs) goes last and orders
# its own members likewise.
phone-uninstall:
	@$(MAKE) --no-print-directory -j1 $(strip $(call reverse,$(PHONE_MODULES:%=%-uninstall)))
	$(call unstow-module,phone)
endif
