ifndef MOD_DESKTOP
MOD_DESKTOP := 1

# Machine identity for recipes: the goal is the machine (see pubnix.mk).
export MACHINE_TYPE := desktop

DESKTOP_MODULES := base restic dev anki keepassxc firefox emacs xclip wireproxy
$(foreach d,$(DESKTOP_MODULES),$(call include-module,$d))

COMMON_PKGS += tk tcl eza
DEBIAN_PKGS += bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools

.PHONY: desktop
desktop: sys-pkgs $(DESKTOP_MODULES)
	@$(stow-module)
	echo "✓ Desktop profile applied successfully."
	@$(mark-applied)
endif
