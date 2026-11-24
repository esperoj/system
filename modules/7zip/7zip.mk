ifndef MOD_7ZIP
MOD_7ZIP := 1

DEBIAN_PKGS += 7zip
TERMUX_PKGS += p7zip

.PHONY: 7zip
7zip: sys-pkgs
	@install-tool 7z gh:ip7z/7zip 'linux-{XARCH}\.tar\.xz$$' 7zz
endif
