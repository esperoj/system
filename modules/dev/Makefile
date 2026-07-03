.PHONY: dev dev-cfg
dev: sys-pkgs stow
	MODULES_DIR="$(MODULES_DIR)/dev" dot apply dotfiles
dev-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "bats fzf nodejs npm perl python3 python3-pip pipx python3-venv ripgrep shellcheck shfmt tmux vim "

