ifndef MOD_AGE
MOD_AGE := 1

include modules/stow/stow.mk

COMMON_PKGS += age

.PHONY: age age-update age-uninstall
age: sys-pkgs stow
	@$(stow-module)
	install-tool age 'https://dl.filippo.io/age/latest?for={OS}/{ARCH}'

age-update:
	@$(call refresh-module,age)
	install-tool -u age 'https://dl.filippo.io/age/latest?for={OS}/{ARCH}'

age-uninstall:
	@$(call unstow-module,age)
	uninstall-tool age
endif
