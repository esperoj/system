ifndef MOD_DESKTOP
MOD_DESKTOP := 1

DESKTOP_MODULES := base restic dev anki keepassxc firefox emacs xclip wireproxy
$(foreach d,$(DESKTOP_MODULES),$(eval include modules/$d/$d.mk))

COMMON_PKGS += tk tcl eza
DEBIAN_PKGS += bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools

.PHONY: desktop desktop-update desktop-uninstall
desktop: sys-pkgs $(DESKTOP_MODULES)
	@$(stow-module)
	echo "✓ Desktop profile applied successfully."

desktop-update: $(DESKTOP_MODULES:%=%-update)
	@$(call refresh-module,desktop)

# Members uninstall in reverse install order through one serial recursive
# make; base (which owns stow, vault and the CLIs) goes last and orders
# its own members likewise.
desktop-uninstall:
	@$(MAKE) --no-print-directory -j1 $(strip $(call reverse,$(DESKTOP_MODULES:%=%-uninstall)))
	$(call unstow-module,desktop)
endif
