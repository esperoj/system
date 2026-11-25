ifndef MOD_VAULT
MOD_VAULT := 1

include modules/bin/bin.mk

# Which vault-repo modules `make vault` applies. Declared once here because
# every profile wants the same set; a node that differs overrides it per
# invocation instead:
#   make vault VAULT_MODULES="ssh git"
VAULT_MODULES ?= ssh base git rclone

.PHONY: vault vault-uninstall
vault: bin
	@dir="$$HOME/.vault"
	if [ -d "$$dir/.git" ]; then
	    vault apply $(VAULT_MODULES)
	else
	    echo "vault: ~/.vault missing -- skipping vault apply"
	    echo "vault: bring the vault over (README, Commissioning), then: make vault"
	fi
	@$(mark-applied)

vault-uninstall:
	@dir="$$HOME/.vault"
	if [ -d "$$dir/.git" ]; then
	    vault remove $(VAULT_MODULES)
	else
	    echo "vault: ~/.vault missing -- nothing to remove"
	fi
	rm -f "$(STATE_DIR)/modules/vault"
endif
