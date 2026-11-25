ifndef MOD_PKIT_META
MOD_PKIT_META := 1

PKIT_META_MODULES := pkit vault
$(foreach d,$(PKIT_META_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: pkit-meta pkit-meta-update pkit-meta-uninstall
pkit-meta: sys-pkgs $(PKIT_META_MODULES)
	@"$(MODULES_DIR)/pkit/clone-dep" install records

pkit-meta-update:
	@"$(MODULES_DIR)/pkit/clone-dep" update records

pkit-meta-uninstall:
	@"$(MODULES_DIR)/pkit/clone-dep" uninstall records
endif
