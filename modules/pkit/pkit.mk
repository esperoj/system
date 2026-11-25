ifndef MOD_PKIT
MOD_PKIT := 1

PKIT_MODULES := dev
$(foreach d,$(PKIT_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: pkit pkit-update pkit-uninstall
pkit: sys-pkgs $(PKIT_MODULES)
	@$(stow-module)
	"$(MODULES_DIR)/pkit/install"

pkit-update:
	@$(call refresh-module,pkit)
	"$(MODULES_DIR)/pkit/install" update

pkit-uninstall:
	@$(call unstow-module,pkit)
	"$(MODULES_DIR)/pkit/install" uninstall
endif
