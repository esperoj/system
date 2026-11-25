ifndef MOD_STOW
MOD_STOW := 1

COMMON_PKGS += stow

.PHONY: stow stow-update stow-uninstall
stow: sys-pkgs
	@"$(MODULES_DIR)/stow/install"

# The rootless source build is pinned (STOW_VER in modules/stow/install):
# stow is core infrastructure, so upgrading it is a deliberate edit there,
# not an automatic fetch.
stow-update:
	@if [ -x "$$HOME/.local/bin/stow" ]; then echo "stow: local build is pinned; bump STOW_VER in modules/stow/install to upgrade"; else echo "✓ stow provided by the host; its package manager updates it"; fi

stow-uninstall:
	@"$(MODULES_DIR)/stow/install" uninstall
endif
