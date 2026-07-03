.PHONY: base base-cfg
BASE_DEPS=7zip age bin env fossil git jq lib rclone shell ssh stow vault
base: sys-pkgs $(BASE_DEPS)
base-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(BASE_DEPS))
	@kv append "apt-pkgs" "ca-certificates coreutils curl findutils gawk gpg iputils-ping make moreutils rename sed sudo time wget unzip xz-utils "
	mkdir -p "$$HOME/.config/env"
