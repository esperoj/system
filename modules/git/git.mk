ifndef MOD_GIT
MOD_GIT := 1

include modules/ssh/ssh.mk

COMMON_PKGS += git

.PHONY: git git-update git-uninstall
git: sys-pkgs ssh

git-update:
	@echo "✓ git: host package (git); its package manager updates it"

git-uninstall:
	@echo "✓ git: host package (git); its package manager removes it"
endif
