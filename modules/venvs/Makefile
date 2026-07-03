.PHONY: venvs venvs-cfg
venvs: env
	rm -rf "$$VENVS_PATH"
	mkdir -p "$$VENVS_PATH"
	python3 -m venv "$$VENVS_PATH/system"
	"$$VENVS_PATH/system/bin/pip" install \
		"perma-store @ https://esperoj.alwaysdata.net/perma-store/tarball/trunk/perma-store.tar.gz" \
		"curl @ https://esperoj.eu.org/perma-tools/tarball/trunk/perma-tools.tar.gz#subdirectory=tools/curl"
venvs-cfg: sys-pkgs-cfg .WAIT env-cfg
