ifndef MOD_PCSX2
MOD_PCSX2 := 1

# The PS2 emulator. Debian carries no pcsx2 package at all, so this is
# fetch-only: the upstream Qt AppImage, a self-contained executable
# fetch-bin installs as-is. AppImages mount themselves through FUSE,
# hence libfuse2t64. On-demand on the desktop, deliberately not part of
# the desktop profile.
DEBIAN_PKGS += libfuse2t64

.PHONY: pcsx2 pcsx2-update
pcsx2: sys-pkgs
	@install-tool pcsx2 gh:PCSX2/pcsx2 'pcsx2-v[0-9.]*\.{OS}-appimage-{XARCH}-Qt\.AppImage$$'
	@$(mark-applied)

pcsx2-update: pcsx2
	@install-tool --update pcsx2 gh:PCSX2/pcsx2 'pcsx2-v[0-9.]*\.{OS}-appimage-{XARCH}-Qt\.AppImage$$'
endif
