ifndef MOD_SHELL
MOD_SHELL := 1

include modules/stow/stow.mk

# No bash-completion package here: the stowed completion is self-contained
# (pure bash builtins), and .bashrc sources the system library only when the
# host already provides it. A package requirement would push every rootless
# node through the sys-pkgs barrier for something it does not need.
COMMON_PKGS += bash

.PHONY: shell shell-update shell-uninstall
shell: sys-pkgs stow
	@$(stow-module)

shell-update:
	@$(call refresh-module,shell)

shell-uninstall:
	@$(call unstow-module,shell)
endif
