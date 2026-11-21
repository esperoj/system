ifndef MOD_VAULT
MOD_VAULT := 1

VAULT_MODULES := bin

$(foreach d,$(VAULT_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: vault
vault: sys-pkgs $(VAULT_MODULES)
	dir="$$HOME/.vault"
	if [ ! -d "$$dir/.git" ]; then
	    echo "vault: ~/.vault missing — skipping vault apply (first commissioning?).";
	    echo "vault: seed or 'vault init [remote]', then run 'make vault'.";
	else
	    cd "$$dir"
	    vault apply * 
	fi
endif
