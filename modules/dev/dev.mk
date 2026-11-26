ifndef MOD_DEV
MOD_DEV := 1

include modules/stow/stow.mk

COMMON_PKGS += fzf tmux vim ripgrep shellcheck shfmt jq
DEBIAN_PKGS += build-essential patch bats nodejs npm python3 python3-pip pipx python3-venv
TERMUX_PKGS += clang make python nodejs-lts

.PHONY: dev dev-update dev-uninstall
dev: sys-pkgs stow
	@$(stow-module)
	@install-tool shfmt gh:mvdan/sh 'shfmt_v[0-9.]*_{OS}_{ARCH}$$'
	@install-tool shellcheck gh:koalaman/shellcheck 'shellcheck-v[0-9.]*\.{OS}\.{UARCH}\.tar\.xz$$'
	"$(MODULES_DIR)/dev/install"
	@$(mark-applied)

# The pinned BATS_VER is the source of truth for --update (mirrors stow);
# the single-binary tools delegate to install-tool's release records.
dev-update: dev
	@install-tool --update shfmt gh:mvdan/sh 'shfmt_v[0-9.]*_{OS}_{ARCH}$$'
	@install-tool --update shellcheck gh:koalaman/shellcheck 'shellcheck-v[0-9.]*\.{OS}\.{UARCH}\.tar\.xz$$'
	"$(MODULES_DIR)/dev/install" --update

dev-uninstall:
	@MODULES_DIR="$(MODULES_DIR)/dev" dot remove dotfiles
	"$(MODULES_DIR)/dev/uninstall"
	rm -f "$(STATE_DIR)/modules/dev"
endif
