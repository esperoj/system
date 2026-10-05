ifndef MOD_VAULT
MOD_VAULT := 1

include modules/bin/bin.mk

.PHONY: vault
vault: sys-pkgs bin
	@if [ -z "$(strip $(VAULT_MODULES))" ]; then
	    echo "vault: VAULT_MODULES empty — nothing to apply";
	elif [ ! -d "$$HOME/.vault/.git" ]; then
	    echo "vault: VAULT_MODULES set but ~/.vault missing —" >&2;
	    echo "vault: run 'vault init [remote]' or restore a seed first" >&2;
	    exit 1;
	else
	    vault apply $(VAULT_MODULES);
	fi
endif
