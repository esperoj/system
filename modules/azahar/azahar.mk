ifndef MOD_AZAHAR
MOD_AZAHAR := 1

# The 3DS emulator (Citra/Lime3DS successor). No Debian package; the
# release ships one unversioned Linux AppImage per tag — no arch in the
# name — and the tag inside the resolved URL is the release identity
# install-tool compares on --update. On-demand on the desktop,
# deliberately not part of the desktop profile.
DEBIAN_PKGS += libfuse2t64

.PHONY: azahar azahar-update
azahar: sys-pkgs
	@install-tool azahar gh:azahar-emu/azahar 'azahar\.AppImage$$'
	@$(mark-applied)

azahar-update: azahar
	@install-tool --update azahar gh:azahar-emu/azahar 'azahar\.AppImage$$'
endif
