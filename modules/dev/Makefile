.PHONY: dev dev-cfg
dev: sys-pkgs stow ocaml
	MODULES_DIR="$(MODULES_DIR)/dev" dot apply dotfiles
dev-cfg: sys-pkgs-cfg .WAIT stow-cfg ocaml-cfg
	@kv append "apt-pkgs" "build-essential patch bats fzf nodejs npm python3 python3-pip pipx python3-venv ripgrep shellcheck shfmt tmux vim "

