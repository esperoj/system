ifndef MOD_BASE
MOD_BASE := 1

BASE_MODULES := 7zip age bin env git jq lib rclone shell ssh stow vault recipes
$(foreach d,$(BASE_MODULES),$(eval include modules/$d/$d.mk))


COMMON_PKGS += bzip2 parallel ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils zstd
DEBIAN_PKGS += openssh-client gpg rename iputils-ping fd-find
TERMUX_PKGS += openssh gnupg fd


.PHONY: base
base: sys-pkgs $(BASE_MODULES)
	@$(stow-module)
	if command -v fdfind >/dev/null 2>&1; then
		ln -sfn "$(command -v fdfind)" "$$HOME/.local/bin/fd"
	fi
endif
