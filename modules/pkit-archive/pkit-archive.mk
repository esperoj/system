ifndef MOD_PKIT_ARCHIVE
MOD_PKIT_ARCHIVE := 1

PKIT_ARCHIVE_MODULES := pkit vault
$(foreach d,$(PKIT_ARCHIVE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: pkit-archive pkit-archive-update pkit-archive-uninstall
pkit-archive: sys-pkgs $(PKIT_ARCHIVE_MODULES)
	@"$(MODULES_DIR)/pkit/clone-dep" install archive

pkit-archive-update:
	@"$(MODULES_DIR)/pkit/clone-dep" update archive

pkit-archive-uninstall:
	@"$(MODULES_DIR)/pkit/clone-dep" uninstall archive
endif
