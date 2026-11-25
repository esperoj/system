ifndef MOD_PKIT_META
MOD_PKIT_META := 1

PKIT_META_MODULES := pkit vault
$(foreach d,$(PKIT_META_MODULES),$(call include-module,$d))

.PHONY: pkit-meta pkit-meta-uninstall
pkit-meta: sys-pkgs $(PKIT_META_MODULES)
	@"$(MODULES_DIR)/pkit/clone-dep" records
	@$(mark-applied)

pkit-meta-uninstall:
	@echo ":: removing ~/.local/share/pkit/records (a git clone; push first if you have local changes)"
	rm -rf "$$HOME/.local/share/pkit/records"
	rm -f "$(STATE_DIR)/modules/pkit-meta"
endif
