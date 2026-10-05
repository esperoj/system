# 1. Dynamically support Termux vs Desktop paths
SHELL := $(shell which bash 2>/dev/null || echo /bin/bash)
.SHELLFLAGS := -eu -o pipefail -c

# 2. Configure native MAKEFLAGS for speed and clean logging
MAKEFLAGS += -j -Otarget

# 3. Environment/Path Setup
VAULT_DIR     := $(HOME)/.vault

ifeq ($(MACHINE_TYPE),desktop)
    BACKUP_DIR    := $(HOME)/backups
    WORKSPACE_DIR := $(HOME)/workspace
else ifeq ($(MACHINE_TYPE),phone)
    BACKUP_DIR    := /sdcard/backups
    WORKSPACE_DIR := /sdcard/workspace
else
    $(error CRITICAL: Environment variable MACHINE_TYPE must be 'desktop' or 'phone')
endif

# Restic AWS Credentials
export AWS_ACCESS_KEY_ID     := $(RESTIC_BACKUPS_AWS_ACCESS_KEY_ID)
export AWS_SECRET_ACCESS_KEY := $(RESTIC_BACKUPS_AWS_SECRET_ACCESS_KEY)
export RESTIC_REPOSITORY     := $(RESTIC_BACKUPS_REPOSITORY)

# Rclone Remotes
WORKSPACE_RCLONE_REMOTE := workspace:
BACKUPS_RCLONE_REMOTE   := backups:
PCLOUD_REMOTE           := pcloud:

export RESTIC_HOST := $(MACHINE_TYPE)

.PHONY: all daily pre-snap sync-workspace sync-backups sync-media snap clean info init-restic resync

# Default target
all: daily

# Daily routine:
# 1. Snapshot existing backups before sync
# 2. Sync workspace, backups, and machine-specific media
# 3. Snapshot after sync
# 4. Clean/prune
daily: pre-snap .WAIT sync-workspace sync-backups sync-media .WAIT snap .WAIT clean

info:
	@echo "======================================================================"
	echo " TARGET MACHINE TYPE  : $(MACHINE_TYPE)"
	echo " BACKUP TARGET DIR    : $(BACKUP_DIR)"
	echo " WORKSPACE DIR        : $(WORKSPACE_DIR)"
	echo " VAULT DIR            : $(VAULT_DIR)"
	echo "======================================================================"

# Streamlined macro: purely handles regular delta operations
define do_bisync
	mkdir -p "$(1)"
	echo "--> Executing delta sync for $(1)..."
	rclone bisync "$(1)" "$(2)" \
		-v \
		--resilient \
		--recover \
		--conflict-resolve newer \
		--modify-window 2s \
		--fast-list
endef

sync-workspace: info
	@echo "--> Syncing Workspace..."
	$(call do_bisync,$(WORKSPACE_DIR),$(WORKSPACE_RCLONE_REMOTE))

sync-backups: info
	@echo "--> Syncing Backups..."
	$(call do_bisync,$(BACKUP_DIR),$(BACKUPS_RCLONE_REMOTE))

sync-media: info
ifeq ($(MACHINE_TYPE),desktop)
	@echo "--> Syncing PPSSPP config to pcloud..."
	rclone sync $(HOME)/.config/ppsspp/ $(PCLOUD_REMOTE)ppsspp -v
else ifeq ($(MACHINE_TYPE),phone)
	@echo "--> Syncing Android DCIM to pcloud..."
	rclone sync /sdcard/DCIM $(PCLOUD_REMOTE)DCIM -v
endif

init-restic: info
	@if restic snapshots >/dev/null 2>&1; then \
		echo "--> Restic repository already initialized."; \
	else \
		echo "--> Initializing restic cryptographic repository..."; \
		restic init; \
	fi

resync: info
	@echo "--> Performing first-time baseline resync for Workspace..."
	mkdir -p $(WORKSPACE_DIR)
	rclone bisync $(WORKSPACE_DIR) $(WORKSPACE_RCLONE_REMOTE) --resync --verbose --fast-list
	echo "--> Performing first-time baseline resync for Backups..."
	mkdir -p $(BACKUP_DIR)
	rclone bisync $(BACKUP_DIR) $(BACKUPS_RCLONE_REMOTE) --resync --verbose --fast-list

pre-snap: info
	@mkdir -p $(BACKUP_DIR)
	echo "--> Taking pre-sync restic snapshot of BACKUPS folder..."
	restic backup $(BACKUP_DIR) --verbose --exclude-caches --tag pre-sync

snap: info
	@mkdir -p $(BACKUP_DIR)
	echo "--> Taking post-sync restic snapshot of BACKUPS folder..."
	restic backup $(BACKUP_DIR) --verbose --exclude-caches --tag post-sync

clean: info
	@echo "--> Releasing repository lock threads & purging retention indexes..."
	restic unlock
	restic forget \
		--keep-daily 7 \
		--keep-weekly 4 \
		--keep-monthly 12 \
		--prune \
		--verbose
