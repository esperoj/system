ifndef MOD_PHONE
MOD_PHONE := 1

PHONE_MODULES := base shell rclone restic vault git ssh stow
$(foreach d,$(PHONE_MODULES),$(eval include modules/$d/$d.mk))


VAULT_MODULES += ssh base git rclone


.PHONY: phone
phone: sys-pkgs $(PHONE_MODULES)
	@$(stow-module)
	echo "✓ Phone profile applied successfully."
endif
