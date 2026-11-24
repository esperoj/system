ifndef MOD_AGE
MOD_AGE := 1

include modules/stow/stow.mk

COMMON_PKGS += age

.PHONY: age
age: sys-pkgs stow
	@$(stow-module)
	install-tool age 'https://dl.filippo.io/age/latest?for={OS}/{ARCH}'
endif
