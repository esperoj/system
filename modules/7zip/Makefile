.PHONY: 7zip 7zip-cfg
7zip: sys-pkgs
	"$(MODULES_DIR)/7zip/install"
7zip-cfg: sys-pkgs-cfg
	@kv sadd debian-pkgs 7zip
	@kv sadd termux-pkgs p7zip
