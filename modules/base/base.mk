ifndef MOD_BASE
MOD_BASE := 1

include modules/7zip/7zip.mk
include modules/age/age.mk
include modules/bin/bin.mk
include modules/env/env.mk
include modules/git/git.mk
include modules/jq/jq.mk
include modules/lib/lib.mk
include modules/rclone/rclone.mk
include modules/shell/shell.mk
include modules/ssh/ssh.mk
include modules/stow/stow.mk
include modules/vault/vault.mk
include modules/recipes/recipes.mk

COMMON_PKGS += bzip2 parallel ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils zstd
DEBIAN_PKGS += openssh-client gpg rename iputils-ping
TERMUX_PKGS += openssh gnupg

BASE_MODULES := 7zip age bin env git jq lib rclone shell ssh stow vault recipes

.PHONY: base
base: sys-pkgs $(BASE_MODULES)
endif
