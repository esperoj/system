ifndef MOD_PKIT
MOD_PKIT := 1

PKIT_MODULES := dev
$(foreach d,$(PKIT_MODULES),$(eval include modules/$d/$d.mk))


.PHONY: pkit
pkit: sys-pkgs $(PKIT_MODULES)
	@$(stow-module)
	"$(MODULES_DIR)/pkit/install"
endif
