ifndef MOD_PHONE
MOD_PHONE := 1

# Machine identity for recipes: the goal is the machine (see pubnix.mk).
export MACHINE_TYPE := phone

PHONE_MODULES := base restic
$(foreach d,$(PHONE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: phone
phone: sys-pkgs $(PHONE_MODULES)
	@$(stow-module)
	echo "✓ Phone profile applied successfully."
endif
