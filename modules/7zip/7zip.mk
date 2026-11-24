ifndef MOD_7ZIP
MOD_7ZIP := 1

# Both distros package the ip7z release as "7zip" (Debian since trixie;
# Termux ships 7z/7za/7zr/7zz from it).
DEBIAN_PKGS += 7zip
TERMUX_PKGS += 7zip

.PHONY: 7zip
7zip: sys-pkgs
	@install-tool 7z gh:ip7z/7zip 'linux-{XARCH}\.tar\.xz$$' 7zz
endif
