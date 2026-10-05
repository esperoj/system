ifndef MOD_DESKTOP
MOD_DESKTOP := 1

include modules/restic/restic.mk
include modules/stow/stow.mk
include modules/base/base.mk
include modules/dev/dev.mk
include modules/anki/anki.mk
include modules/keepassxc/keepassxc.mk
include modules/firefox/firefox.mk
include modules/emacs/emacs.mk
include modules/xclip/xclip.mk
include modules/crontab/crontab.mk
include modules/wireproxy/wireproxy.mk

COMMON_PKGS   += tk tcl
DEBIAN_PKGS   += bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools
VAULT_MODULES += ssh base git rclone

DESKTOP_MODULES := restic stow base dev anki keepassxc firefox emacs xclip crontab wireproxy

.PHONY: desktop
desktop: sys-pkgs $(DESKTOP_MODULES)
	@MODULES_DIR="$(MODULES_DIR)/desktop" dot apply dotfiles
	@echo "✓ Desktop profile applied successfully."
endif
