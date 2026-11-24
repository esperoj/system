ifndef MOD_DESKTOP
MOD_DESKTOP := 1

DESKTOP_MODULES := base restic dev anki keepassxc firefox emacs xclip wireproxy
$(foreach d,$(DESKTOP_MODULES),$(eval include modules/$d/$d.mk))

COMMON_PKGS += tk tcl eza
DEBIAN_PKGS += bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools

.PHONY: desktop
desktop: sys-pkgs $(DESKTOP_MODULES)
	@$(stow-module)
	echo "✓ Desktop profile applied successfully."
endif
