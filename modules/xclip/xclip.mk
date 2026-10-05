ifndef MOD_XCLIP
MOD_XCLIP := 1

DEBIAN_PKGS += xclip

.PHONY: xclip
xclip: sys-pkgs
endif
