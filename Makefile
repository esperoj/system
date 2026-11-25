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
# Stow the current target's module into $TARGET.
# Recursive '=' on purpose: $@ must expand at recipe time, not definition time.
stow-module = MODULES_DIR="$(MODULES_DIR)/$@" dot apply dotfiles
# Record that the current target's module ran to completion: the membership
# line that scopes `make update` / `make uninstall` (nothing more). Stamps are
# disposable with the rest of .state/; re-running a profile rebuilds them.
mark-applied = mkdir -p "$(STATE_DIR)/modules" && touch "$(STATE_DIR)/modules/$@"

# --- The One Include Idiom ---
# Every module inclusion — goal-driven here, profile-driven in the module
# makefiles — goes through include-module, which reads the file once and
# records it in MODULE_SEEN so no module is read twice per run. That is a
# correctness rule, not an optimization: make's conditional scanner cannot
# skip a guarded file whose recipes open lines with shell conditional words
# (if/else/fi) — it reads the `else` as its own. Keep such logic in module
# scripts; vault.mk's if/else recipe stays single-read behind this macro.
MODULE_SEEN :=
include-module = $(eval MODULE_SEEN += $1)$(eval -include modules/$1/$1.mk)

# --- Goal-Driven Dynamic Inclusion ---
# $(sort) also removes duplicates, so goals are unique + sorted.
# Verb goals are normalised to their module first: `make rclone-update`
# loads rclone.mk, where the explicit verb rule lives beside the install
# rule. The global verbs (update, uninstall) load every module recorded as
# applied (.state/modules/*), so each one's verb rules are visible too.
APPLIED := $(notdir $(wildcard $(STATE_DIR)/modules/*))
GOALS := $(sort $(if $(MAKECMDGOALS),$(MAKECMDGOALS),help) $(if $(filter update uninstall,$(MAKECMDGOALS)),$(APPLIED)))
GOALS := $(sort $(patsubst %-uninstall,%,$(patsubst %-update,%,$(GOALS))))
 $(foreach g,$(GOALS),$(if $(filter $(g),$(MODULE_SEEN)),,$(call include-module,$(g))))

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

.PHONY: sys-pkgs clean-state help lint fmt review setup-remotes update uninstall

sys-pkgs: $(STAMP)

clean-state:
	rm -rf $(STATE_DIR)

# --- Module Verbs: <module>-update / <module>-uninstall ---
# Two generic pattern rules give every module goal its verbs; a module that
# needs more declares an explicit rule, which always beats the pattern (the
# same precedence make uses everywhere). Defaults, honestly minimal:
#
#   %-update      re-apply the goal: stow relinks whatever `git pull` brought,
#                 the package barrier and PATH guards skip finished work.
#   %-uninstall   unstow the module's dotfiles, drop fetched tools that
#                 install-tool recorded, forget the applied stamp. System
#                 packages are the host's, and are reported, not removed.
%-update: %
	@echo ":: $* re-applied"
%-uninstall:
	@if [ -d "$(MODULES_DIR)/$*/dotfiles" ]; then
	    MODULES_DIR="$(MODULES_DIR)/$*" dot remove dotfiles
	fi
	if [ -d "$${XDG_STATE_HOME:-$$HOME/.local/state}/system/tools/$*" ]; then
	    uninstall-tool "$*"
	fi
	rm -f "$(STATE_DIR)/modules/$*"
	echo ":: $* uninstalled (system packages, if any, remain the host's)"

# `make update`: every module recorded applied, in one DAG, one process.
# Fetched tools re-download only when upstream actually changed; everything
# else re-applies with skips. An empty record set (fresh clone, clean-state)
# says so loudly instead of guessing.
update: $(APPLIED:%=%-update)
	@test -n "$(APPLIED)" || echo "update: nothing recorded in $(STATE_DIR)/modules/ — run a profile first, then re-run"

# `make uninstall` is deliberately not a bulk verb: removal should name its
# module. Point at the per-module verbs and list what this node recorded.
uninstall:
	@echo "Usage: make <module>-uninstall   (e.g. make rclone-uninstall make shell-uninstall)"
	echo "Bulk removal is deliberate: it would unlink user-local files sight unseen."
	echo "Modules recorded applied on this node: $(APPLIED)"

# --- Shared Shell Script Finder ---
FIND_SHELL = find bootstrap modules -type f \( -name '*.sh' -o -name 'configure' -o -name 'install' -o -name 'uninstall' -o -name 'setup' -o -name 'bootstrap' -o -path '*/.local/bin/*' -o -path '*/.local/lib/sh/*' \) -print0

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
	echo "Utility targets:"
	echo "  help         Show this help"
	echo "  lint         Run shellcheck and shfmt checks (read-only)"
	echo "  fmt          Format shell scripts in-place using shfmt"
	echo "  review       Run Aider review on the latest commit"
	echo "  clean-state  Wipe .state/ cache to force package reinstall"
	echo ""
	echo "Module verbs (every module goal has them):"
	echo "  <m>-update    refresh one module, e.g. make rclone-update"
	echo "  <m>-uninstall remove one module, e.g. make rclone-uninstall"
	echo "  update        refresh every module recorded applied (fetched"
	echo "                tools re-download only when upstream changed)"

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
