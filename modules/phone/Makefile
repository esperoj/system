.PHONY: phone phone-cfg
PHONE_DEPS = base shell rclone restic vault fossil git ssh stow
phone: sys-pkgs $(PHONE_DEPS)
	dot apply "$(MODULES_DIR)/phone/dotfiles"
phone-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(PHONE_DEPS))
