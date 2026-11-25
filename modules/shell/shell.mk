ifndef MOD_SHELL
MOD_SHELL := 1

include modules/stow/stow.mk

COMMON_PKGS += bash bash-completion

.PHONY: shell shell-update shell-uninstall
shell: sys-pkgs stow
	@$(stow-module)

shell-update:
	@$(call refresh-module,shell)

shell-uninstall:
	@$(call unstow-module,shell)
endif
