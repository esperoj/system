ifndef MOD_RUNIT
MOD_RUNIT := 1

DEBIAN_PKGS += runit
TERMUX_PKGS += runit

.PHONY: runit
runit: sys-pkgs
endif
