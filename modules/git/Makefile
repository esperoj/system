.PHONY: git git-cfg
git: sys-pkgs ssh
git-cfg: sys-pkgs-cfg .WAIT ssh-cfg
	@kv sadd apt-pkgs git
