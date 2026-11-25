ifndef MOD_GIT
MOD_GIT := 1

include modules/ssh/ssh.mk

COMMON_PKGS += git

.PHONY: git
git: sys-pkgs ssh
endif
