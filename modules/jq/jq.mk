ifndef MOD_JQ
MOD_JQ := 1

COMMON_PKGS += jq

.PHONY: jq jq-update jq-uninstall
jq: sys-pkgs
	@install-tool jq gh:jqlang/jq 'jq-{OS}-{ARCH}$$'

jq-update:
	@install-tool -u jq gh:jqlang/jq 'jq-{OS}-{ARCH}$$'

jq-uninstall:
	@uninstall-tool jq
endif
