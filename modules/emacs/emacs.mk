ifndef MOD_EMACS
MOD_EMACS := 1

include modules/stow/stow.mk
include modules/git/git.mk

COMMON_PKGS += pandoc
DEBIAN_PKGS += emacs-gtk elpa-markdown-mode elpa-magit elpa-yaml-mode
TERMUX_PKGS += emacs

.PHONY: emacs
emacs: sys-pkgs git stow
	@$(stow-module)
endif
