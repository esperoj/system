ifndef MOD_VAULT
MOD_VAULT := 1

include modules/bin/bin.mk

.PHONY: vault
vault: sys-pkgs bin
	@if [ -z "$(strip $(VAULT_MODULES))" ]; then
	    echo "vault: VAULT_MODULES empty — nothing to apply";
	elif [ ! -d "$$HOME/.vault/.git" ]; then
	    echo "vault: ~/.vault missing — skipping vault apply (first commissioning?).";
	    echo "vault: seed or 'vault init [remote]', then run 'make vault'.";
	else
	    vault apply $(VAULT_MODULES);
	fi
endif
