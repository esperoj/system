ifndef MOD_PHONE
MOD_PHONE := 1

include modules/base/base.mk
include modules/shell/shell.mk
include modules/rclone/rclone.mk
include modules/restic/restic.mk
include modules/vault/vault.mk
include modules/git/git.mk
include modules/ssh/ssh.mk
include modules/stow/stow.mk

VAULT_MODULES += ssh base git rclone

PHONE_MODULES := base shell rclone restic vault git ssh stow

.PHONY: phone
phone: sys-pkgs $(PHONE_MODULES)
	@MODULES_DIR="$(MODULES_DIR)/phone" dot apply dotfiles
	echo "✓ Phone profile applied successfully."
endif
