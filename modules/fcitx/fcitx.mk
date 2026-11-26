ifndef MOD_FCITX
MOD_FCITX := 1

include modules/stow/stow.mk

# Input methods for the desktop: Pinyin (Simplified Chinese) via
# fcitx5-chinese-addons, Telex (Vietnamese) via fcitx5-unikey — which
# already defaults to Telex, so the stowed profile's input-method list
# (keyboard, pinyin, unikey) is the whole setup. The toolkit frontends
# wire GTK and Qt applications to the daemon. Debian's package ships no
# /etc/xdg/autostart entry, hence the module's own autostart file.
DEBIAN_PKGS += fcitx5 fcitx5-chinese-addons fcitx5-unikey fcitx5-frontend-gtk3 fcitx5-frontend-gtk4 fcitx5-frontend-qt6

.PHONY: fcitx fcitx-uninstall
fcitx: sys-pkgs stow
	@$(stow-module)
	@$(mark-applied)

fcitx-uninstall:
	@MODULES_DIR="$(MODULES_DIR)/fcitx" dot remove dotfiles
	rm -f "$(STATE_DIR)/modules/fcitx"
endif
