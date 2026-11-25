ifndef MOD_FIREFOX
MOD_FIREFOX := 1

DEBIAN_PKGS += firefox-esr

.PHONY: firefox firefox-update firefox-uninstall
firefox: sys-pkgs

firefox-update:
	@echo "✓ firefox: host package (firefox-esr); its package manager updates it"

firefox-uninstall:
	@echo "✓ firefox: host package (firefox-esr); its package manager removes it"
endif
