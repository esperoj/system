.ONESHELL:

# 1. Correct the special SHELL variable and dynamically support Termux vs Desktop paths
SHELL := $(shell which bash 2>/dev/null || echo /bin/bash)
.SHELLFLAGS := -eu -o pipefail -c

# 2. Configure native MAKEFLAGS:
# -j           -> Unlimited parallel jobs
# -Otarget     -> Synchronize and group output by target (prevents log interleaving)
MAKEFLAGS += -j -Otarget

ifeq ($(MACHINE_TYPE),desktop)
    WORKSPACE_DIR := $(HOME)/workspace
else ifeq ($(MACHINE_TYPE),phone)
    WORKSPACE_DIR := /sdcard/workspace
else
    $(error CRITICAL: Environment variable MACHINE_TYPE must be 'desktop' or 'phone')
endif

RCLONE_BISYNC_CACHE := $(HOME)/.cache/rclone/bisync

export AWS_ACCESS_KEY_ID     := $(RESTIC_BACKUPS_AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY := $(RESTIC_BACKUPS_AWS_SECRET_ACCESS_KEY)
export RESTIC_REPOSITORY     := $(RESTIC_BACKUPS_REPOSITORY)

WORKSPACE_RCLONE_REMOTE := workspace:

.PHONY: all sync snap clean info

all: sync snap

info:
	@echo "======================================================================"
	@echo " TARGET MACHINE TYPE  : $(MACHINE_TYPE)"
	@echo " ACTIVE WORKSPACE DIR : $(WORKSPACE_DIR)"
	@echo " RCLONE CACHE TARGET  : $(RCLONE_BISYNC_CACHE)"
	@echo "======================================================================"

sync: info
	@mkdir -p $(WORKSPACE_DIR)
	@if [ -z "$$(ls -A $(RCLONE_BISYNC_CACHE) 2>/dev/null)" ]; then \
		echo "--> [Auto-Init] Cache state missing. Running baseline bisync alignment..."; \
		rclone bisync $(WORKSPACE_DIR) $(WORKSPACE_RCLONE_REMOTE) --resync --verbose --fast-list; \
	else \
		echo "--> Operational cache state detected. Executing delta workspace sync..."; \
		rclone bisync $(WORKSPACE_DIR) $(WORKSPACE_RCLONE_REMOTE) \
			--verbose \
			--resilient \
			--recover \
			--conflict-resolve newer \
			--fast-list; \
	fi

snap: info
	@mkdir -p $(WORKSPACE_DIR)
	@echo "--> Initializing restic cryptographic snapshot upload..."
	restic backup $(WORKSPACE_DIR) --verbose --exclude-caches

clean: info
	@echo "--> Releasing repository lock threads & purging retention indexes..."
	restic unlock
	restic forget \
		--keep-daily 7 \
		--keep-weekly 4 \
		--keep-monthly 12 \
		--prune \
		--verbose
	restic cache --cleanup

