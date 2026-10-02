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

.PHONY: help lint

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
	@echo "  lint         Run shellcheck/shfmt/static checks"

lint:
	@rc=0; \
	if command -v shellcheck >/dev/null 2>&1; then \
		find configure modules \
			\( \
				\( -type f -name '*.sh' \) -o \
				\( -type f -name configure \) -o \
				\( -type f -name install \) -o \
				\( -type f -name setup \) -o \
				\( -type f -path '*/.local/bin/*' \) -o \
				\( -type f -path '*/.local/lib/sh/*' \) \
			\) \
			-print0 | xargs -0 -r shellcheck --severity=error || rc=1; \
	else \
		echo "lint: shellcheck not found; skipping"; \
	fi; \
	if command -v shfmt >/dev/null 2>&1; then \
		find configure modules \
			\( \
				\( -type f -name '*.sh' \) -o \
				\( -type f -name configure \) -o \
				\( -type f -name install \) -o \
				\( -type f -name setup \) -o \
				\( -type f -path '*/.local/bin/*' \) -o \
				\( -type f -path '*/.local/lib/sh/*' \) \
			\) \
			-print0 | xargs -0 -r shfmt -d || rc=1; \
	else \
		echo "lint: shfmt not found; skipping"; \
	fi; \
	exit $$rc
