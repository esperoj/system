ifndef MOD_AGE
MOD_AGE := 1

include modules/stow/stow.mk

COMMON_PKGS += age

.PHONY: age age-update
age: sys-pkgs stow
	@$(stow-module)
	install-tool age 'https://dl.filippo.io/age/latest?for={OS}/{ARCH}'
	@$(mark-applied)

# The source is a floating "latest" link: install-tool follows the
# redirect and compares the actual asset, so an unchanged release is a
# no-download skip.
age-update: age
	@install-tool --update age 'https://dl.filippo.io/age/latest?for={OS}/{ARCH}'
endif
