ifndef MOD_ENV
MOD_ENV := 1

include modules/stow/stow.mk

.PHONY: env env-update env-uninstall
env: sys-pkgs stow
	@$(stow-module)

env-update:
	@$(call refresh-module,env)

env-uninstall:
	@$(call unstow-module,env)
endif
