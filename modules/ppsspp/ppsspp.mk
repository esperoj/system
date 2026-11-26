ifndef MOD_PPSSPP
MOD_PPSSPP := 1

# The PSP emulator. Not in Debian either; upstream ships "anylinux"
# AppImages named with uname-style arches (x86_64) — the UARCH
# placeholder exists for exactly that naming. On-demand on the desktop,
# deliberately not part of the desktop profile.
DEBIAN_PKGS += libfuse2t64

.PHONY: ppsspp ppsspp-update
ppsspp: sys-pkgs
	@install-tool ppsspp gh:hrydgard/ppsspp 'PPSSPP-v[0-9.]*-anylinux-{UARCH}\.AppImage$$'
	@$(mark-applied)

ppsspp-update: ppsspp
	@install-tool --update ppsspp gh:hrydgard/ppsspp 'PPSSPP-v[0-9.]*-anylinux-{UARCH}\.AppImage$$'
endif
