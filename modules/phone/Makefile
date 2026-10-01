.PHONY: phone phone-cfg
PHONE_DEPS = base shell rclone restic vault git ssh stow
phone: sys-pkgs $(PHONE_DEPS)
	MODULES_DIR="$(MODULES_DIR)/phone" dot apply dotfiles
phone-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(PHONE_DEPS))
	@kv sadd vault-modules ssh base git rclone
