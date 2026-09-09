.PHONY: anki anki-cfg
anki: sys-pkgs
	"$(MODULES_DIR)/anki/install"
anki-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "libxcb-xinerama0 libxcb-cursor0 libnss3 libxcb-icccm4 libxcb-keysyms1 "

