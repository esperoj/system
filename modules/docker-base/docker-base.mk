ifndef MOD_DOCKER_BASE
MOD_DOCKER_BASE := 1

include modules/stow/stow.mk
include modules/base/base.mk
include modules/wireproxy/wireproxy.mk

DOCKER_BASE_MODULES := stow base wireproxy

.PHONY: docker-base
docker-base: sys-pkgs $(DOCKER_BASE_MODULES)
	@MODULES_DIR="$(MODULES_DIR)/docker-base" dot apply dotfiles
	@sudo apt-get clean || true
	@sudo rm -rf /var/lib/apt/lists/* || true
	@echo "✓ Docker base profile applied successfully."
endif
