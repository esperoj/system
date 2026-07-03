.PHONY: docker-base
DOCKER_BASE_DEPS = stow base wireproxy
docker-base: sys-pkgs $(DOCKER_BASE_DEPS)
	MODULES_DIR="$(MODULES_DIR)/docker-base" dot apply dotfiles
docker-base-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(DOCKER_BASE_DEPS))
#	@kv append "apt-pkgs" ""
