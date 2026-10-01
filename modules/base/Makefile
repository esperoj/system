.PHONY: base base-cfg
BASE_DEPS=7zip age bin env git jq lib rclone shell ssh stow vault recipes
base: sys-pkgs $(BASE_DEPS)
base-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(BASE_DEPS))
	@kv sadd common-pkgs parallel ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils zstd
	@kv sadd debian-pkgs openssh-client gpg rename iputils-ping
	@kv sadd termux-pkgs openssh gnupg
	@mkdir -p "$$HOME/.config/env"
