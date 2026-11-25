ifndef MOD_RUNIT
MOD_RUNIT := 1

DEBIAN_PKGS += runit
TERMUX_PKGS += runit

.PHONY: runit runit-update runit-uninstall
runit: sys-pkgs

runit-update:
	@echo "✓ runit: host package (runit); its package manager updates it"

runit-uninstall:
	@echo "✓ runit: host package (runit); its package manager removes it"
endif
