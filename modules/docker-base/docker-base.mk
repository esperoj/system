ifndef MOD_DOCKER_BASE
MOD_DOCKER_BASE := 1

# Machine identity for recipes: the goal is the machine (see pubnix.mk).
export MACHINE_TYPE := docker-base

DOCKER_BASE_MODULES := base wireproxy
$(foreach d,$(DOCKER_BASE_MODULES),$(call include-module,$d))

.PHONY: docker-base
docker-base: sys-pkgs $(DOCKER_BASE_MODULES)
	@$(stow-module)
	echo "✓ Docker base profile applied successfully."
	@$(mark-applied)
endif
