.PHONY: emacs emacs-cfg
emacs: stow sys-pkgs
	mkdir -p ~/.config/emacs
	MODULES_DIR="$(MODULES_DIR)/emacs" dot apply dotfiles
	# sudo npm install -g bash-language-server vscode-langservers-extracted
emacs-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv append "apt-pkgs" "pandoc emacs-gtk elpa-markdown-mode elpa-magit elpa-tuareg"

