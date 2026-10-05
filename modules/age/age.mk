ifndef MOD_AGE
MOD_AGE := 1

include modules/stow/stow.mk

COMMON_PKGS += age

.PHONY: age
age: sys-pkgs stow
	@MODULES_DIR="$(MODULES_DIR)/age" dot apply dotfiles
	@"$(MODULES_DIR)/age/install"
endif
