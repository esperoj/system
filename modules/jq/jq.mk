ifndef MOD_JQ
MOD_JQ := 1

COMMON_PKGS += jq

.PHONY: jq jq-update
jq: sys-pkgs
	@install-tool jq gh:jqlang/jq 'jq-{OS}-{ARCH}$$'
	@$(mark-applied)

jq-update: jq
	@install-tool --update jq gh:jqlang/jq 'jq-{OS}-{ARCH}$$'
endif
