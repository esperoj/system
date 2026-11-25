ifndef MOD_PUBNIX
MOD_PUBNIX := 1

# The goal is the machine. Exporting it here means the very first
# commissioning run -- before pubnix.env is stowed into ~/.config/env --
# already behaves rootless, and every recipe below sees the identity.
export MACHINE_TYPE := pubnix

PUBNIX_MODULES := base dev crontab wireproxy
$(foreach d,$(PUBNIX_MODULES),$(call include-module,$d))

.PHONY: pubnix
pubnix: sys-pkgs $(PUBNIX_MODULES)
	@$(stow-module)
	echo "✓ Pubnix profile applied successfully."
	@$(mark-applied)
endif
