ifndef MOD_JQ
MOD_JQ := 1

COMMON_PKGS += jq

.PHONY: jq
jq: sys-pkgs
	@install-tool jq gh:jqlang/jq 'jq-{OS}-{ARCH}$$'
endif
