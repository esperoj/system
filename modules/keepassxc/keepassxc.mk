ifndef MOD_KEEPASSXC
MOD_KEEPASSXC := 1

DEBIAN_PKGS += keepassxc

.PHONY: keepassxc
keepassxc: sys-pkgs
endif
