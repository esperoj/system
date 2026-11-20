ifndef MOD_PKIT_META
MOD_PKIT_META := 1

PKIT_META_MODULES := pkit vault
$(foreach d,$(PKIT_META_MODULES),$(eval include modules/$d/$d.mk))


.PHONY: pkit-meta
pkit-meta: sys-pkgs $(PKIT_META_MODULES)
	@"$(MODULES_DIR)/pkit-meta/install"
endif
