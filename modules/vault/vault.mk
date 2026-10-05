ifndef MOD_VAULT
MOD_VAULT := 1

include modules/bin/bin.mk
include modules/lib/lib.mk
include modules/git/git.mk
include modules/ssh/ssh.mk
include modules/stow/stow.mk

.PHONY: vault
vault: sys-pkgs bin lib git ssh stow
	@"$(MODULES_DIR)/vault/setup"
endif
