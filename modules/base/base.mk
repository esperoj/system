ifndef MOD_BASE
MOD_BASE := 1

BASE_MODULES := 7zip age bin env git jq lib rclone shell ssh stow vault recipes
$(foreach d,$(BASE_MODULES),$(eval include modules/$d/$d.mk))

COMMON_PKGS += bzip2 parallel ca-certificates coreutils curl findutils gawk make moreutils sed time wget unzip xz-utils zstd
DEBIAN_PKGS += openssh-client gpg rename iputils-ping fd-find sudo
TERMUX_PKGS += openssh gnupg fd

.PHONY: base base-update base-uninstall
base: sys-pkgs $(BASE_MODULES)

base-update: $(BASE_MODULES:%=%-update)

# Members uninstall in reverse install order, with stow held back to the
# very end: every `dot remove` needs the stow binary until the last module
# has been unstowed. One recursive serial make (-j1) gives both the order
# and the ordering guarantee under the parallel parent.
base-uninstall:
	@$(MAKE) --no-print-directory -j1 $(strip $(filter-out stow-uninstall,$(call reverse,$(BASE_MODULES:%=%-uninstall)))) stow-uninstall
endif
