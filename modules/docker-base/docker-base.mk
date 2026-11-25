ifndef MOD_DOCKER_BASE
MOD_DOCKER_BASE := 1

DOCKER_BASE_MODULES := base wireproxy
$(foreach d,$(DOCKER_BASE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: docker-base docker-base-update docker-base-uninstall
docker-base: sys-pkgs $(DOCKER_BASE_MODULES)
	@$(stow-module)
	echo "✓ Docker base profile applied successfully."

docker-base-update: $(DOCKER_BASE_MODULES:%=%-update)
	@$(call refresh-module,docker-base)

docker-base-uninstall:
	@$(MAKE) --no-print-directory -j1 $(strip $(call reverse,$(DOCKER_BASE_MODULES:%=%-uninstall)))
	$(call unstow-module,docker-base)
endif
