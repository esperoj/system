ifndef MOD_WIREPROXY
MOD_WIREPROXY := 1

include modules/stow/stow.mk

.PHONY: wireproxy wireproxy-update
wireproxy: sys-pkgs stow
	@install-tool wireproxy gh:whyvl/wireproxy 'wireproxy_linux_{ARCH}\.tar\.gz$$'
	$(stow-module)
	@$(mark-applied)

wireproxy-update: wireproxy
	@install-tool --update wireproxy gh:whyvl/wireproxy 'wireproxy_linux_{ARCH}\.tar\.gz$$'
endif
