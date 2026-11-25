ifndef MOD_VAULT
MOD_VAULT := 1

include modules/bin/bin.mk

# Which vault-repo modules `make vault` applies. Declared once here because
# every profile wants the same set; a node that differs overrides it per
# invocation instead:
#   make vault VAULT_MODULES="ssh git"
VAULT_MODULES ?= ssh base git rclone

# Single-line shell conditionals throughout: tab-prefixed shell keywords
# (else/fi at line start) break GNU make's guarded re-parse of a module
# file included a second time -- `make base vault` used to die with
# "recipe commences before first target".
.PHONY: vault vault-update vault-uninstall
vault: bin
	@if [ -d "$$HOME/.vault/.git" ]; then vault apply $(VAULT_MODULES); else { echo "vault: ~/.vault missing -- skipping vault apply"; echo "vault: bring the vault over (README, Commissioning), then: make vault"; } fi

vault-update:
	@if [ -d "$$HOME/.vault/.git" ]; then vault sync; else echo "vault: ~/.vault missing -- nothing to update"; fi

vault-uninstall:
	@if [ -d "$$HOME/.vault/.git" ]; then vault remove $(VAULT_MODULES); else echo "vault: ~/.vault missing -- nothing to remove"; fi
endif
