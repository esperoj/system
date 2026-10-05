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

# --- Goal-Driven Dynamic Inclusion ---
# Includes only the module matching the invoked target (e.g., make desktop -> modules/desktop/desktop.mk)
# Submodules recursively include their own dependencies with ifndef guards.
GOALS := $(if $(MAKECMDGOALS),$(MAKECMDGOALS),help)
$(foreach g,$(GOALS),$(eval -include modules/$(g)/$(g).mk))

# --- Export Accumulated Sets to Subprocesses ---
export COMMON_PKGS DEBIAN_PKGS TERMUX_PKGS ALPINE_PKGS FREEBSD_PKGS VAULT_MODULES

# --- System Package Barrier ---
$(STATE_DIR)/sys-pkgs.stamp: $(MAKEFILE_LIST)
	@mkdir -p $(STATE_DIR)
	@install-sys-pkg
	@touch $@

.PHONY: sys-pkgs clean-state help lint fmt review

sys-pkgs: $(STATE_DIR)/sys-pkgs.stamp

clean-state:
	rm -rf $(STATE_DIR)

# --- Shared Shell Script Finder ---
FIND_SHELL = find bootstrap modules -type f \( -name '*.sh' -o -name 'configure' -o -name 'install' -o -name 'setup' -o -path '*/.local/bin/*' -o -path '*/.local/lib/sh/*' \) -print0

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Primary targets:"
	@echo "  desktop      Debian desktop node"
	@echo "  phone        Termux mobile node"
	@echo "  pubnix       Rootless shared UNIX node"
	@echo "  docker-base  Container base image environment"
	@echo ""
	@echo "Submodule targets:"
	@echo "  emacs, git, dev, base, wireproxy, etc."
	@echo ""
	@echo "Utility targets:"
	@echo "  help         Show this help"
	@echo "  lint         Run shellcheck and shfmt checks (read-only)"
	@echo "  fmt          Format shell scripts in-place using shfmt"
	@echo "  review       Run Aider review on the latest commit"
	@echo "  clean-state  Wipe .state/ cache to force package reinstall"

lint:
	@rc=0
	if command -v shellcheck >/dev/null 2>&1; then
		echo ":: Running shellcheck..."
		$(FIND_SHELL) | xargs -0 -r shellcheck --severity=error || rc=1
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
	Review the latest commit against the design principles, constraints, and architecture outlined in README.md and the codebase structure.
	Identify any bugs, architectural deviations, or unnecessary complexity.

	Latest Commit Diff:
	MSG
	git show HEAD >> "$$msg_file"
	model="$${AIDER_MODEL:-gemini/gemini-flash-latest}"
	aider --model "$$model" --read README.md --message-file "$$msg_file"
