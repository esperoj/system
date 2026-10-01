.PHONY: dev dev-cfg
dev: sys-pkgs stow ocaml
	MODULES_DIR="$(MODULES_DIR)/dev" dot apply dotfiles
dev-cfg: sys-pkgs-cfg .WAIT stow-cfg ocaml-cfg
	@kv sadd common-pkgs fzf tmux vim ripgrep shellcheck shfmt jq
	@kv sadd debian-pkgs build-essential patch bats nodejs npm python3 python3-pip pipx python3-venv
	@kv sadd termux-pkgs clang make python nodejs-lts
