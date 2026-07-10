# ==============================================================================
# Environment Guard & Path Mapping
# ==============================================================================
ifeq ($(MACHINE_TYPE),desktop)
    WORKSPACE_DIR  := $(HOME)/workspace
    BACKUP_DIR     := $(HOME)/backups
else ifeq ($(MACHINE_TYPE),phone)
    WORKSPACE_DIR  := /sdcard/workspace
    BACKUP_DIR     := /sdcard/backups
else
    $(error CRITICAL: Environment variable MACHINE_TYPE must be explicitly set to 'desktop' or 'phone')
endif

# Load isolated Tigris credentials without overriding global env
ifneq ("$(wildcard .env.tigris)","")
    include .env.tigris
    export AWS_ACCESS_KEY_ID := $(TIGRIS_ACCESS_KEY_ID)
    export AWS_SECRET_ACCESS_KEY := $(TIGRIS_SECRET_ACCESS_KEY)
    export RESTIC_PASSWORD := $(RESTIC_PASSWORD)
endif

# ==============================================================================
# Global Parameters
# ==============================================================================
RCLONE_REMOTE      := workspace:
RESTIC_REPOSITORY  := s3:https://t3.storage.dev/esperoj-restic-backups

RETENTION_DAILY    := 7
RETENTION_WEEKLY   := 4
RETENTION_MONTHLY  := 12

.PHONY: all info sync-workspace init-bisync backup-data maintenance verify-repo

all: info sync-workspace backup-data

info:
	@echo "======================================================================"
	@echo " MACHINE_TYPE Env Target : $(MACHINE_TYPE)"
	@echo " Configured Workspace    : $(WORKSPACE_DIR)"
	@echo "======================================================================"

# ==============================================================================
# Rclone Bisync Sub-System
# ==============================================================================

init-bisync:
	@echo "--> Initializing base bisync alignment (First-time run)..."
	@mkdir -p $(WORKSPACE_DIR)
	rclone bisync $(WORKSPACE_DIR) $(RCLONE_REMOTE) \
		--resync \
		--verbose \
		--fast-list

sync-workspace:
	@echo "--> Executing operational workspace bisync..."
	@mkdir -p $(WORKSPACE_DIR)
	rclone bisync $(WORKSPACE_DIR) $(RCLONE_REMOTE) \
		--verbose \
		--resilient \
		--recover \
		--conflict-resolve newer \
		--fast-list

# ==============================================================================
# Restic Cryptographic Backup Sub-System
# ==============================================================================

## Adjusted to backup WORKSPACE_DIR so it actually saves your active files
backup-data:
	@echo "--> Initializing restic snapshot upload..."
	@mkdir -p $(WORKSPACE_DIR)
	restic -r $(RESTIC_REPOSITORY) backup $(WORKSPACE_DIR) \
		--verbose \
		--exclude-caches

maintenance:
	@echo "--> Releasing processing repository locks..."
	restic -r $(RESTIC_REPOSITORY) unlock
	@echo "--> Applying snapshot expiration retention policy..."
	restic -r $(RESTIC_REPOSITORY) forget \
		--keep-daily $(RETENTION_DAILY) \
		--keep-weekly $(RETENTION_WEEKLY) \
		--keep-monthly $(RETENTION_MONTHLY) \
		--prune \
		--verbose
	@echo "--> Pruning local client structural indexes..."
	restic cache --cleanup

verify-repo:
	@echo "--> Performing repository integrity check..."
	restic -r $(RESTIC_REPOSITORY) check --read-data

