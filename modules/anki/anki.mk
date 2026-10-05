ifndef MOD_ANKI
MOD_ANKI := 1

DEBIAN_PKGS += libxcb-xinerama0 libxcb-cursor0 libnss3 libxcb-icccm4 libxcb-keysyms1

.PHONY: anki
anki: sys-pkgs
	@"$(MODULES_DIR)/anki/install"
endif
