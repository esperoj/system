VAULT_DEPS = age bin lib
vault: sys-pkgs $(VAULT_DEPS)
	@"$(MODULES_DIR)/vault/setup"
vault-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg, $(VAULT_DEPS))
