ifndef MOD_FIREFOX
MOD_FIREFOX := 1

DEBIAN_PKGS += firefox-esr

.PHONY: firefox
firefox: sys-pkgs
endif
