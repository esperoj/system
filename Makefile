.ONESHELL:
.SHELLFLAGS = -eu -c
MAKEFLAGS   += -j
SHELL       := /bin/sh
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

MODULES_DIR := $(CURDIR)/modules
STATE_DIR   := $(CURDIR)/.state
BIN_DIR     := $(MODULES_DIR)/bin/dotfiles/.local/bin
LIB_DIR     := $(MODULES_DIR)/lib/dotfiles/.local/lib
PATH        := $(BIN_DIR):$(HOME)/.local/bin:$(PATH)

export PATH LIB_DIR MODULES_DIR STATE_DIR

# --- Shared Recipe Macros ---
# stow-module: stow the current target's module into $TARGET (install path).
# Recursive '=' on purpose: $@ must expand at recipe time, not definition time.
stow-module = MODULES_DIR="$(MODULES_DIR)/$@" dot apply dotfiles

# refresh-module / unstow-module name the module explicitly, so they also
# work for the -update/-uninstall goals where $@ is not the module name.
# refresh only touches modules already applied: update never installs.
refresh-module = if MODULES_DIR="$(MODULES_DIR)/$(1)" dot applied dotfiles; then MODULES_DIR="$(MODULES_DIR)/$(1)" dot apply dotfiles; else echo "✓ $(1) not applied; skipping"; fi
unstow-module = if MODULES_DIR="$(MODULES_DIR)/$(1)" dot applied dotfiles; then MODULES_DIR="$(MODULES_DIR)/$(1)" dot remove dotfiles; else echo "✓ $(1) not applied; nothing to unstow"; fi

# $(call reverse,a b c) -> c b a. Uninstall walks the install DAG backwards.
reverse = $(if $(strip $(1)),$(call reverse,$(wordlist 2,$(words $(1)),$(1))) $(firstword $(1)))

# --- Goal-Driven Dynamic Inclusion ---
# $(sort) also removes duplicates, so goals are unique + sorted.
# modules/<goal>/<goal>.mk is included per goal; submodules recursively
# include their own dependencies behind ifndef guards.
# Verb suffixes (-update, -uninstall) are stripped before the module lookup,
# so `make rclone-update` and `make rclone-uninstall` both load
# modules/rclone/rclone.mk, which defines the module's whole lifecycle.
GOALS := $(sort $(if $(MAKECMDGOALS),$(MAKECMDGOALS),help))
MODULE_GOALS := $(sort $(foreach g,$(GOALS),$(firstword $(subst -update, ,$(subst -uninstall, ,$(g))))))
 $(foreach g,$(MODULE_GOALS),$(eval -include modules/$(g)/$(g).mk))

# --- Export Accumulated Sets to Subprocesses ---
export COMMON_PKGS DEBIAN_PKGS TERMUX_PKGS ALPINE_PKGS FREEBSD_PKGS

# --- System Package Barrier (package-set-keyed stamp) ---
# One stamp per exact accumulated package set (all distro lists hashed
# together after every module has parsed, above). Consequences:
#   - re-running the same profile with no package changes is a no-op;
#   - switching or combining goals (make desktop lint) never reinstalls;
#   - a module edit that changes any package list produces a new key and
#     installs exactly once;
#   - switching back to a previous profile reuses its stamp.
# Old stamps linger in .state/ until `make clean-state`; the directory is
# disposable at any moment.
PKG_SET := common=$(COMMON_PKGS) debian=$(DEBIAN_PKGS) termux=$(TERMUX_PKGS) alpine=$(ALPINE_PKGS) freebsd=$(FREEBSD_PKGS)
PKG_KEY := $(shell printf '%s' '$(PKG_SET)' | cksum | cut -d' ' -f1)
STAMP := $(STATE_DIR)/sys-pkgs-$(PKG_KEY).stamp

$(STAMP):
	@mkdir -p $(STATE_DIR)
	install-sys-pkg
	touch $@

.PHONY: sys-pkgs clean-state update help lint fmt review setup-remotes

sys-pkgs: $(STAMP)

clean-state:
	rm -rf $(STATE_DIR)

# --- Module Lifecycle: Global Update ---
# Every directory under modules/ is a module. `make update` refreshes the
# applied footprint of each one via its <module>-update target; every module
# self-skips where it was never applied, so this composes into "update
# everything this node actually uses". One recursive make so the goal-driven
# inclusion above loads every module file; the final prune drops links whose
# files were removed from the repo. Update never installs anything new and
# never touches system packages (the host package manager owns those).
ALL_MODULES := $(sort $(notdir $(patsubst %/,%,$(wildcard $(MODULES_DIR)/*/))))

update:
	@$(MAKE) --no-print-directory $(ALL_MODULES:%=%-update)
	dot prune
	echo "✓ Update complete."

# --- Shared Shell Script Finder ---
FIND_SHELL = find bootstrap modules -type f \( -name '*.sh' -o -name 'configure' -o -name 'install' -o -name 'uninstall' -o -name 'setup' -o -name 'bootstrap' -o -path '*/.local/bin/*' -o -path '*/.local/lib/sh/*' -o -path '*/bash-completion/completions/*' \) -print0

help:
	@echo "Usage: make <target>"
	echo ""
	echo "Primary targets:"
	echo "  base         Core profile: tools only, no secrets (every node)"
	echo "  desktop      Debian desktop node (base + rest)"
	echo "  phone        Termux mobile node (base + restic)"
	echo "  pubnix       Rootless shared UNIX node"
	echo "  docker-base  Container base image environment"
	echo ""
	echo "Secrets (after the vault arrives):"
	echo "  vault        Apply vault modules (VAULT_MODULES, default ssh base git rclone)"
	echo ""
	echo "Submodule targets:"
	echo "  emacs, git, dev, wireproxy, pkit-meta, ..."
	echo ""
	echo "Module lifecycle (every module, e.g. rclone):"
	echo "  rclone-update     Update one module (no redownload when already latest)"
	echo "  rclone-uninstall  Remove one module's user-local footprint"
	echo ""
	echo "Utility targets:"
	echo "  update       Update every applied module, then prune stale links"
	echo "  help         Show this help"
	echo "  lint         Run shellcheck and shfmt checks (read-only)"
	echo "  fmt          Format shell scripts in-place using shfmt"
	echo "  review       Run Aider review on the latest commit"
	echo "  clean-state  Wipe .state/ cache to force package reinstall"

lint:
	@rc=0
	if command -v shellcheck >/dev/null 2>&1; then
	    echo ":: Running shellcheck..."
	    $(FIND_SHELL) | xargs -0 -r shellcheck || rc=1
	else
	    echo "lint: shellcheck not found; skipping"
	fi
	if command -v shfmt >/dev/null 2>&1; then
	    echo ":: Running shfmt check..."
	    $(FIND_SHELL) | xargs -0 -r shfmt -d || rc=1
	else
	    echo "lint: shfmt not found; skipping"
	fi
	exit $$rc

fmt:
	@if command -v shfmt >/dev/null 2>&1; then
	    echo ":: Formatting shell scripts with shfmt..."
	    $(FIND_SHELL) | xargs -0 -r shfmt -w
	    echo "✓ Formatting complete."
	else
	    echo "fmt: shfmt not found; please install shfmt to format code."
	    exit 1
	fi

review:
	@if ! command -v aider >/dev/null 2>&1; then
	    echo "review: aider not found; please install aider-chat to run reviews." >&2
	    exit 1
	fi
	echo ":: Running Aider review on latest commit..."
	msg_file=$$(mktemp)
	trap 'rm -f "$$msg_file"' EXIT INT TERM
	cat <<-'MSG' > "$$msg_file"
	Review the latest commit against the design principles, constraints, and architecture outlined in README.org and the codebase structure.
	Identify any bugs, architectural deviations, or unnecessary complexity.
	Latest Commit Diff:
	MSG
	git show HEAD >> "$$msg_file"
	model="$${AIDER_MODEL:-gemini/gemini-flash-latest}"
	aider --model "$$model" --read README.org --message-file "$$msg_file"

setup-remotes:
	@git config --remove-section remote.origin
	git remote add origin git@github.com:esperoj/system.git
	git remote set-url --push origin git@github.com:esperoj/system.git
	git remote set-url --add --push origin git@codefloe.com:esperoj/system.git
	echo "Remotes configured:"
	git remote -v
