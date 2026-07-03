.PHONY: base base-cfg
BASE_DEPS=7zip age bin env fossil git jq lib rclone shell ssh stow vault
base: sys-pkgs $(BASE_DEPS)
base-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(BASE_DEPS))
	@kv append "apt-pkgs" "ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils "
	CORE_PKGS="openssh-client gpg"
	if [ "$$(uname -o 2>/dev/null)" = "Android" ] || [ -n "$$TERMUX_VERSION" ]; then
	  kv append "apt-pkgs" "openssh gnupg "
	else
	  kv append "apt-pkgs" "$$CORE_PKGS rename iputils-ping "
	fi
	mkdir -p "$$HOME/.config/env"
