.PHONY: stow stow-cfg
STOW_OPTS ?= -v
export STOW_OPTS
stow: sys-pkgs
	"$(MODULES_DIR)/stow/install"
stow-cfg: sys-pkgs-cfg
	@kv append "apt-pkgs" "stow "

