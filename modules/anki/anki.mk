ifndef MOD_ANKI
MOD_ANKI := 1

DEBIAN_PKGS += libxcb-xinerama0 libxcb-cursor0 libnss3 libxcb-icccm4 libxcb-keysyms1

.PHONY: anki anki-update anki-uninstall
anki: sys-pkgs
	@"$(MODULES_DIR)/anki/install"
	@$(mark-applied)

anki-update: anki
	@"$(MODULES_DIR)/anki/install" --update

anki-uninstall:
	@"$(MODULES_DIR)/anki/uninstall"
	rm -f "$(STATE_DIR)/modules/anki"
endif
