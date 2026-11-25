ifndef MOD_PKIT
MOD_PKIT := 1

PKIT_MODULES := dev
$(foreach d,$(PKIT_MODULES),$(call include-module,$d))


.PHONY: pkit pkit-uninstall
pkit: sys-pkgs $(PKIT_MODULES)
	@$(stow-module)
	"$(MODULES_DIR)/pkit/install"
	@$(mark-applied)

pkit-uninstall:
	@echo ":: removing ~/projects/pkit (a git clone; re-clonable)"
	rm -rf "$$HOME/projects/pkit"
	rm -f "$(STATE_DIR)/modules/pkit"
endif
