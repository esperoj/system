ifndef MOD_DOCKER_BASE
MOD_DOCKER_BASE := 1

DOCKER_BASE_MODULES := stow base wireproxy
$(foreach d,$(DOCKER_BASE_MODULES),$(eval include modules/$d/$d.mk))



.PHONY: docker-base
docker-base: sys-pkgs $(DOCKER_BASE_MODULES)
	@$(stow-module)
	sudo apt-get clean || true
	sudo rm -rf /var/lib/apt/lists/* || true
	echo "✓ Docker base profile applied successfully."
endif
