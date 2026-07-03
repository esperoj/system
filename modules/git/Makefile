.PHONY: git git-cfg
git: sys-pkgs vault ssh
git-cfg: sys-pkgs-cfg .WAIT vault-cfg ssh-cfg
	@kv append "apt-pkgs" "git "
