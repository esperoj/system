.ONESHELL:
.SHELLFLAGS = -e -c
MAKEFLAGS   += -j
SHELL       := /bin/sh
.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

MODULES_DIR := $(CURDIR)/modules
BIN_DIR     := $(MODULES_DIR)/bin/dotfiles/.local/bin
LIB_DIR     := $(MODULES_DIR)/lib/dotfiles/.local/lib
PATH        := $(BIN_DIR):$(HOME)/.local/bin:$(PATH)
KV_STORE    := $(CURDIR)/.kv-store
LC_ALL      := C
export PATH LIB_DIR KV_STORE LC_ALL

-include $(MODULES_DIR)/*/Makefile

# --- Shared Shell Script Finder (DRY) ---
# Safely finds all shell scripts, entrypoints, and library files
FIND_SHELL = find configure modules -type f \( -name '*.sh' -o -name 'configure' -o -name 'install' -o -name 'setup' -o -path '*/.local/bin/*' -o -path '*/.local/lib/sh/*' \) -print0

.PHONY: help lint fmt review

help:
	@echo "Usage: ./configure <target> && make <target>"
	@echo ""
	@echo "Primary targets:"
	@echo "  desktop      Debian desktop node"
	@echo "  phone        Termux mobile node"
	@echo "  pubnix       Rootless shared UNIX node"
	@echo "  docker-base  Container base image environment"
	@echo ""
	@echo "Utility targets:"
	@echo "  help         Show this help"
	@echo "  lint         Run shellcheck and shfmt checks (read-only)"
	@echo "  fmt          Format shell scripts in-place using shfmt"
	@echo "  review       Run Aider review on the latest commit with full repo context"

lint:
	@rc=0; \
	if command -v shellcheck >/dev/null 2>&1; then \
		echo ":: Running shellcheck..."; \
		$(FIND_SHELL) | xargs -0 -r shellcheck --severity=error || rc=1; \
	else \
		echo "lint: shellcheck not found; skipping"; \
	fi; \
	if command -v shfmt >/dev/null 2>&1; then \
		echo ":: Running shfmt check..."; \
		$(FIND_SHELL) | xargs -0 -r shfmt -d || rc=1; \
	else \
		echo "lint: shfmt not found; skipping"; \
	fi; \
	exit $$rc

fmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		echo ":: Formatting shell scripts with shfmt..."; \
		$(FIND_SHELL) | xargs -0 -r shfmt -w; \
		echo "✓ Formatting complete."; \
	else \
		echo "fmt: shfmt not found; please install shfmt to format code."; \
		exit 1; \
	fi

review:
	@if command -v aider >/dev/null 2>&1; then \
		echo ":: Running Aider review on latest commit..."; \
		aider --model gemini/gemini-flash-latest \
			--message "Review the latest commit against the design principles, constraints, and architecture outlined in README.md and the codebase structure. \
			\n\nLatest Commit Diff:\n$$(git show HEAD)\n\n \
			Identify any bugs, architectural deviations, or unnecessary complexity."; \
	else \
		echo "review: aider not found; please install aider-chat to run reviews."; \
		exit 1; \
	fi
