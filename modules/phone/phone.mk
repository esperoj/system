ifndef MOD_PHONE
MOD_PHONE := 1

PHONE_MODULES := base restic
$(foreach d,$(PHONE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: phone
phone: sys-pkgs $(PHONE_MODULES)
	@$(stow-module)
	echo "✓ Phone profile applied successfully."
endif
