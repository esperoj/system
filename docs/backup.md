# Multi-Platform Backup & Sync System
A robust synchronization and backup engine that bridges your desktop environment and Android device (via Termux). It utilizes rclone bisync for a bidirectional cloud-synchronized workspace/ folder and restic to push securely encrypted, deduplicated snapshots of your backups/ folder directly to Tigris S3 storage.
## Architectural Layout
```
                        +----------------------------+
                        |         Tigris S3          |
                        |  (Restic Backup Target)    |
                        +--------------+-------------+
                                       ^
                                       | (restic backup)
                                       |
    +----------------------------------+----------------------------------+
    |                                                                     |
    v                                                                     v
+-----------+    (rclone bisync)    +---------------+    (rclone bisync)    +---------+
|  Desktop  | <===================> | rclone Remote | <===================> |  Phone  |
| (~/)      |                       | (workspace:)  |                       | (/sdcard|
+-----------+                       +---------------+                       +---------+

```
## Prerequisites & Credentials
Ensure your terminal environment has access to the required profiles before running the orchestration suite:
 1. **Rclone Remote:** Your local rclone.conf must contain a configured storage remote named workspace:.
 2. **Restic Parameters:** Export the required authentication and cryptographic values into your shell configuration file (.bashrc, .zshrc, or Termux script):
   ```bash
   export RESTIC_REPOSITORY="opendal:s3:your-tigris-bucket-name"
   export RESTIC_PASSWORD="your-strong-repository-encryption-password"
   export AWS_ACCESS_KEY_ID="your-tigris-s3-access-key"
   export AWS_SECRET_ACCESS_KEY="your-tigris-s3-secret-key"
   
   ```
## Deployment & Operational Lifecycle
### 1. First-Time Initialization (--resync)
rclone bisync functions by tracking state via structural base caches. When a path pairing is linked for the absolute first time, both devices **must run the initialization routine exactly once**.
Running the default target *before* initializing will result in an error to safeguard against unintended data loss.
```bash
# On your Desktop Computer:
export MACHINE_TYPE=desktop
make init-workspace

# On your Android Device (via Termux):
export MACHINE_TYPE=phone
make init-workspace

```
### 2. Normal Everyday Execution
Once initial synchronization structures have been generated and aligned on the cloud remote, utilize the standard targets. The system maps directory paths conditionally using your exported MACHINE_TYPE (desktop maps to ~/, while phone maps to /sdcard).
```bash
# Execute both workspace synchronization and backup tasks sequentially
MACHINE_TYPE=desktop make all

# Run bidirectional workspace synchronization only
MACHINE_TYPE=phone make sync-workspace

# Snapshot your localized backup folder to Tigris S3 only
MACHINE_TYPE=desktop make backup-data

```
### 3. Maintenance & Repository Upkeep (Run Weekly)
Restic backs up changes incrementally, leaving deleted and outdated file histories inside storage chunks. To clean up expired snapshots, verify data block integrity against bit rot, and purge localized system caches, execute:
```bash
MACHINE_TYPE=desktop make maintenance verify-repo

```
## Headless Background Automation
### A. Linux / macOS Cron Integration
Open your system's personal user crontab configuration editor via crontab -e and register a cron rule to sync and backup your data every 30 minutes, with deep repository cleanup executing every Sunday morning:
```cron
# Automatically synchronize workspace and backup data every 30 minutes
*/30 * * * * export MACHINE_TYPE=desktop; cd /path/to/project && make all > /dev/null 2>&1

# Run structural restic compression and purge rules every Sunday at 3:00 AM
0 3 * * 0 export MACHINE_TYPE=desktop; cd /path/to/project && make maintenance > /dev/null 2>&1

```
### B. Android Automation (Termux + Tasker / MacroDroid)
 1. Install the **Termux:Tasker** plugin application to allow third-party Android apps to safely hook into the Termux environment.
 2. Build an isolated shell automation script under your execution directory at ~/.termux/tasker/run_sync.sh:
   ```bash
   #!/usr/bin/env bash
   export MACHINE_TYPE=phone
   # Export key environmental secrets if they are not persistently sourced
   export RESTIC_PASSWORD="your-strong-repository-encryption-password"
   
   cd /sdcard/path/to/project && make all
   
   ```
 3. Set up a rule in **MacroDroid** or **Tasker** that calls this script automatically whenever your device connects to your home Wi-Fi network or plugs into power overnight.
## Disaster Recovery & Troubleshooting
### Dealing with Bisync Lock/Out-of-Sync Errors
If a simultaneous conflict occurs across both devices, or if an execution is interrupted, rclone bisync will freeze and generate a lock file to prevent destructive overrides.
If you are confident that your local or cloud paths represent the state you wish to enforce, run the break-glass target to force a complete cache re-alignment:
```bash
MACHINE_TYPE=desktop make resolve-conflict

```

