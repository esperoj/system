ifndef MOD_BASE
MOD_BASE := 1

BASE_MODULES := 7zip age bin env git jq lib rclone shell ssh stow vault recipes
$(foreach d,$(BASE_MODULES),$(eval include modules/$d/$d.mk))


COMMON_PKGS += bzip2 parallel ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils zstd
DEBIAN_PKGS += openssh-client gpg rename iputils-ping
TERMUX_PKGS += openssh gnupg


.PHONY: base
base: sys-pkgs $(BASE_MODULES)
endif
