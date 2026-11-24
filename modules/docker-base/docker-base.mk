ifndef MOD_DOCKER_BASE
MOD_DOCKER_BASE := 1

DOCKER_BASE_MODULES := base wireproxy
$(foreach d,$(DOCKER_BASE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: docker-base
docker-base: sys-pkgs $(DOCKER_BASE_MODULES)
	@$(stow-module)
	echo "✓ Docker base profile applied successfully."
endif
