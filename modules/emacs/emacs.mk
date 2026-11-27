ifndef MOD_EMACS
MOD_EMACS := 1

EMACS_MODULES := git stow
$(foreach d,$(EMACS_MODULES),$(call include-module,$d))

COMMON_PKGS += pandoc
DEBIAN_PKGS += emacs-gtk elpa-markdown-mode elpa-magit elpa-yaml-mode
TERMUX_PKGS += emacs

.PHONY: emacs
emacs: sys-pkgs $(EMACS_MODULES)
	@$(stow-module)
	@$(mark-applied)
endif
