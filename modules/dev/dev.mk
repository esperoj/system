ifndef MOD_DEV
MOD_DEV := 1

include modules/stow/stow.mk

COMMON_PKGS += fzf tmux vim ripgrep shellcheck shfmt jq
DEBIAN_PKGS += build-essential patch bats nodejs npm python3 python3-pip pipx python3-venv
TERMUX_PKGS += clang make python nodejs-lts

.PHONY: dev
dev: sys-pkgs stow
	@$(stow-module)
endif
