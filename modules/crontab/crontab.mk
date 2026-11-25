ifndef MOD_CRONTAB
MOD_CRONTAB := 1

include modules/stow/stow.mk

DEBIAN_PKGS += cron
TERMUX_PKGS += cronie

# Single-line shell conditionals throughout: tab-prefixed shell keywords
# (else/fi at line start) break GNU make's guarded re-parse of a module
# file that was already included once (see vault.mk).
.PHONY: crontab crontab-update crontab-uninstall
crontab: sys-pkgs stow
	@$(stow-module)
	file="$$HOME/.config/crontab/crontab"
	if [ "$$(crontab -l 2>/dev/null || true)" = "$$(cat "$$file" 2>/dev/null || true)" ]; then echo "✓ crontab already loaded"; else crontab "$$file"; echo "✓ crontab loaded"; fi

crontab-update:
	@$(call refresh-module,crontab)
	file="$$HOME/.config/crontab/crontab"
	if [ -f "$$file" ] && [ "$$(crontab -l 2>/dev/null || true)" != "$$(cat "$$file")" ]; then crontab "$$file"; echo "✓ crontab reloaded"; else echo "✓ crontab already up to date"; fi

crontab-uninstall:
	@file="$$HOME/.config/crontab/crontab"
	loaded="$$(crontab -l 2>/dev/null || true)"
	if [ -n "$$loaded" ] && [ "$$loaded" = "$$(cat "$$file" 2>/dev/null || true)" ]; then crontab -r; echo "✓ removed the managed crontab"; else echo "✓ crontab absent or locally modified; leaving it alone"; fi
	$(call unstow-module,crontab)
endif
