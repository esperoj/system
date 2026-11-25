ifndef MOD_XCLIP
MOD_XCLIP := 1

DEBIAN_PKGS += xclip

.PHONY: xclip xclip-update xclip-uninstall
xclip: sys-pkgs

xclip-update:
	@echo "✓ xclip: host package (xclip); its package manager updates it"

xclip-uninstall:
	@echo "✓ xclip: host package (xclip); its package manager removes it"
endif
