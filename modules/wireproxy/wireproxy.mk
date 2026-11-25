ifndef MOD_WIREPROXY
MOD_WIREPROXY := 1

include modules/stow/stow.mk

.PHONY: wireproxy wireproxy-update wireproxy-uninstall
wireproxy: sys-pkgs stow
	@install-tool wireproxy gh:whyvl/wireproxy 'wireproxy_linux_{ARCH}\.tar\.gz$$'
	$(stow-module)

wireproxy-update:
	@install-tool -u wireproxy gh:whyvl/wireproxy 'wireproxy_linux_{ARCH}\.tar\.gz$$'
	$(call refresh-module,wireproxy)

wireproxy-uninstall:
	@$(call unstow-module,wireproxy)
	uninstall-tool wireproxy
endif
