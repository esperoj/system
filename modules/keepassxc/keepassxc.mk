ifndef MOD_KEEPASSXC
MOD_KEEPASSXC := 1

DEBIAN_PKGS += keepassxc

.PHONY: keepassxc keepassxc-update keepassxc-uninstall
keepassxc: sys-pkgs

keepassxc-update:
	@echo "✓ keepassxc: host package (keepassxc); its package manager updates it"

keepassxc-uninstall:
	@echo "✓ keepassxc: host package (keepassxc); its package manager removes it"
endif
