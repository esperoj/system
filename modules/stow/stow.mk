ifndef MOD_STOW
MOD_STOW := 1

COMMON_PKGS += stow

.PHONY: stow stow-update stow-uninstall
stow: sys-pkgs
	@"$(MODULES_DIR)/stow/install"
	@$(mark-applied)

# The pinned version is the source of truth: --update rebuilds only when
# STOW_VER in the install script differs from the recorded build.
stow-update: stow
	@"$(MODULES_DIR)/stow/install" --update

stow-uninstall:
	@uninstall-tool stow
	rm -f "$(STATE_DIR)/modules/stow"
endif
