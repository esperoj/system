VAULT_DEPS = bin lib git
vault: sys-pkgs $(VAULT_DEPS)
	@"$(MODULES_DIR)/vault/setup"
vault-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg, $(VAULT_DEPS))
