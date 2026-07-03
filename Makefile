.ONESHELL:
.SHELLFLAGS = -e -c

MAKEFLAGS   += -j
SHELL       := /bin/sh
MODULES_DIR := $(CURDIR)/modules
BIN_DIR     := $(MODULES_DIR)/bin/dotfiles/.local/bin
LIB_DIR     := $(MODULES_DIR)/lib/dotfiles/.local/lib
PATH        := $(BIN_DIR):$(HOME)/.local/bin:$(PATH)
KV_STORE    := $(CURDIR)/.kv-store

export PATH LIB_DIR KV_STORE

-include $(MODULES_DIR)/*/Makefile
