ifndef MOD_JQ
MOD_JQ := 1

COMMON_PKGS += jq

.PHONY: jq
jq: sys-pkgs
	@"$(MODULES_DIR)/jq/install"
endif
