ifndef MOD_PKIT_ARCHIVE
MOD_PKIT_ARCHIVE := 1

PKIT_ARCHIVE_MODULES := pkit vault
$(foreach d,$(PKIT_ARCHIVE_MODULES),$(call include-module,$d))

.PHONY: pkit-archive pkit-archive-uninstall
pkit-archive: sys-pkgs $(PKIT_ARCHIVE_MODULES)
	@"$(MODULES_DIR)/pkit/clone-dep" archive
	@$(mark-applied)

pkit-archive-uninstall:
	@echo ":: removing ~/.local/share/pkit/archive (a git clone; push first if you have local changes)"
	rm -rf "$$HOME/.local/share/pkit/archive"
	rm -f "$(STATE_DIR)/modules/pkit-archive"
endif
