# System Architecture & Sovereign Node Specification

## 1. Meta-Directive & Core Philosophy

This computing environment is a personal sovereign system designed to remain fully understandable, buildable, and operable for **30+ years** without platform lock-in, vendor dependency, or maintenance fatigue.

To eliminate redundancy, the philosophy is defined through **four non-overlapping First Principles**, from which all technical choices logically derive.

```
FIRST PRINCIPLES                 DERIVED ARCHITECTURAL INVARIANTS
┌───────────────────────────┐    ┌───────────────────────────────────────────────┐
│ 1. 30-Year Longevity      │───>│ Ubiquitous UNIX tooling; zero platform lock-in │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 2. Anti-Complexity        │───>│ Low cognitive overhead; inspectable text state│
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 3. Structural Safety      │───>│ Hardware-level boundary; atomic operations    │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 4. Frictionless Flow      │───>│ Sub-millisecond logins; zero runtime locks     │
└───────────────────────────┘    └───────────────────────────────────────────────┘
```

---

### Axiom 1: 30-Year Longevity
* **First Principle:** Code, formats, and tooling must be readable and executable three decades from now using standard C89/POSIX primitives.
* **What We Avoid:** Ephemeral configuration frameworks (Nix, Ansible, Chef), commercial forge APIs, dynamic package manifests, and fragile package managers that break on API changes.
* **Derived Standard:** Everything is written in POSIX shell, GNU Make, standard Git, plain text, and GNU Stow.

### Axiom 2: Anti-Complexity & Low Cognitive Load
* **First Principle:** An operator must be able to hold the entire system state in their head and inspect it with standard utilities (`cat`, `ls`, `grep`, `find`).
* **What We Avoid:** Daemons, background file watchers, stateful SQLite databases for daily config, abstract dotfile managers (Chezmoi), and nested directory boilerplate.
* **Derived Standard:** Caches and build artifacts are 100% disposable. State lives in flat text files. System configuration uses a flat key-value store with standard Redis semantics.

### Axiom 3: Structural Safety over Runtime Mechanics
* **First Principle:** Resilience comes from clear, hardware-enforced boundaries and atomic operations, not automated self-healing scripts or runtime encryption wrappers.
* **What We Avoid:** Runtime RAMFS mounts, real-time decrypt-on-login hooks, and custom encrypted filesystems.
* **Derived Standard:** Full-disk encryption (LUKS on Linux, File-Based Encryption on Android) forms the security perimeter at rest. Cold offsite archives enforce streaming `age` encryption only when crossing network boundaries.

### Axiom 4: Frictionless Ergonomics
* **First Principle:** Daily interactive tooling must be immediate, tactile, and transparent.
* **What We Avoid:** Shell startup latency, passphrase prompts when opening a terminal, and background credential synchronization.
* **Derived Standard:** Shell login scripts (`.profile`) contain zero network calls, zero stow commands, and zero decryption steps. Interactive Git is driven cleanly by native tooling and Emacs Magit.

---

## 2. Implementation Derivation Matrix

Every technical implementation choice in this repository maps directly back to the First Principles:

| Architectural Component | Implementation Choice | Governing Principle | Rationale |
| :--- | :--- | :--- | :--- |
| **Build Engine** | `./configure` + `Makefile` | **Longevity & Simplicity** | Native to all UNIX systems; requires zero external runtimes to bootstrap. |
| **State Bus (`kv`)** | POSIX CLI with Redis API (`SADD`, `SMEMBERS`) | **Anti-Complexity** | Avoids redundant package manager calls via bulk batching without introducing a database daemon. |
| **Package Delivery** | 3-Tier Model (Apt / Pkg / `fetch-bin`) | **Longevity & Maintenance** | Separates system packages from rootless targets and fast-moving binaries without vendor lock-in. |
| **Binary Fetcher** | Direct HTTP & HTML asset scraping (`fetch-bin`) | **Longevity & Resilience** | Eliminates GitHub REST API token requirements and 60 req/hr rate limits. |
| **Vault Storage** | Unencrypted Git at `~/.vault` (flat root) | **Ergonomics & Safety** | Relies on host LUKS/FBE; eliminates RAMFS, Fossil locks, and startup delays. |
| **Remote Sync** | Bare Git repository over SSH on private VPS | **Anti-Complexity** | Decouples sync from commercial clouds; uses native Git mechanics (`git push`). |
| **Dotfile Linking** | GNU Stow via POSIX `dot` wrapper | **Anti-Complexity** | Clear, standard symlinks; zero custom sync daemons or proprietary tracking state. |
| **Offsite Backups** | Streaming `tar \| age` (`backup create`) | **Structural Safety** | Explicit cryptographic boundary applied strictly when data leaves the node. |

---

## 3. Subsystem Architecture

### 3.1 The State Bus: Redis-Compatible `kv`
The `./configure` script acts as a fast probe that interrogates the host node and populates `.kv-store`. To prevent package manager lock contention, `kv` implements Redis Set semantics:

* **Storage Scheme:**
  * Strings: `.kv-store/strings/<key>`
  * Sets: `.kv-store/sets/<set_name>/<member>` (empty marker files)
  * Hashes: `.kv-store/hashes/<hash_name>/<field>`
* **Commands:**
  * `kv SADD <set> <member...>`: Adds unique members atomically without string manipulation.
  * `kv SMEMBERS <set>`: Dumps unique set members for bulk operations (`apt-get install $(kv SMEMBERS apt-pkgs)`).
  * `kv SET / GET / DEL`: Standard scalar key operations.

### 3.2 The 3-Tier Package Delivery Engine
To balance system stability with rootless environments and fast-evolving CLI tools:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PACKAGE DELIVERY PIPELINE                       │
├──────────────────────────┬─────────────────────────┬───────────────────┤
│ Tier 1: Debian/Ubuntu    │ Tier 2: Android/Termux  │ Tier 3: Pubnix    │
│ Bulk apt-get             │ Bulk pkg install        │ fetch-bin         │
│ (System infrastructure)  │ (User-space Termux env) │ (User ~/.local/bin)│
└──────────────────────────┴─────────────────────────┴───────────────────┘
```

* **`fetch-bin` Engine:** When a tool must be cutting-edge (`rclone`, `uv`, `restic`) or runs on a rootless pubnix node:
  1. Resolves tags via HTTP redirects (`/releases/latest` -> `/tag/<TAG>`).
  2. Extracts download links directly from GitHub's `/releases/expanded_assets/<TAG>` HTML (bypassing REST API rate limits completely).
  3. Downloads, unpacks (`tar`, `zip`, `bz2`, `zstd`), and places binaries in `~/.local/bin` with `chmod 755`.

### 3.3 Sovereign Vault (`~/.vault`) & VPS Sync
Private keys, credentials, and sensitive configurations live in an unencrypted Git repository directly at `~/.vault`:

* **Flat Hierarchy:** The root of `~/.vault` directly maps to Stow packages (e.g., `~/.vault/ssh/`, `~/.vault/rclone/`). Non-stow assets are prefixed with `_` or `.` (e.g., `_keys/`).
* **Permissions Invariant:** Directories are locked to `0700`; files are locked to `0600` automatically by `vault chmod`.
* **VPS Synchronization:** A standard bare Git repository on your private VPS (`repos:srv/git/vault.git`) acts as the synchronization hub over SSH.
* **Setup-Time Stowing:** Vault modules are stowed **once** during `make <target>` based on environment declarations (`kv smembers vault-modules`), never inside `.profile` at login.

---

## 4. Repository Layout

```text
.
├── configure                     # POSIX probe and kv state generator
├── Makefile                      # Declarative build runner
├── Dockerfile                    # Container target for reproducible base builds
├── modules/
│   ├── base/                     # Core system dependencies
│   ├── bin/                      # System CLI tools (kv, dot, vault, fetch-bin, backup)
│   ├── dev/                      # Development tooling (tmux, vim, compiler toolchains)
│   ├── desktop/                  # XFCE/GUI configurations and autostart entries
│   ├── emacs/                    # Built-in modern IDE config (Eglot, Treesit, Magit)
│   ├── lib/                      # Shared POSIX shell libraries (os.sh, fetch.sh)
│   ├── phone/                    # Android/Termux specific profiles
│   ├── pubnix/                   # Shared rootless server profiles
│   ├── shell/                    # Minimalist .bashrc, .profile, .inputrc
│   └── vault/                    # Private vault setup hooks and automation
└── store/                        # Canonical assets and long-term stores
```

---

## 5. Node Commissioning & Bootstrap Manual

### 5.1 Preparing the Trust Root
A new node cannot pull its cryptographic identity out of thin air. Before provisioning, choose your trust root:

* **Method A (Networked / SSH Agent):** If setting up remotely from your existing machine, use SSH Agent Forwarding:
  ```sh
  ssh -A user@new-node
  ```
* **Method B (Offline / Cold Seed):** Generate a streaming `age`-encrypted cold archive of your vault on an established node:
  ```sh
  backup create ~/.vault ~/vault-seed.tar.gz.age
  ```
  Transfer `vault-seed.tar.gz.age` and your `age` identity key to the target machine via USB or local transfer.

---

### 5.2 Desktop Node Bootstrap (Debian / LUKS)
* **Perimeter:** Hardware Full-Disk Encryption (LUKS).
* **Access:** User with `sudo`.

```sh
# 1. Install bare bootstrap dependencies
sudo apt-get update && sudo apt-get install -y git make curl ca-certificates

# 2. Clone system repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and execute bulk build
./configure desktop
make desktop

# 4. Provision Vault
# Option 4a: Using SSH identity
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /path/to/id_ed25519 ~/.ssh/id_ed25519 && chmod 600 ~/.ssh/id_ed25519
vault init repos:srv/git/vault.git

# Option 4b: Using cold backup
backup restore /path/to/vault-seed.tar.gz.age ~/.vault
vault chmod
vault apply ssh rclone wireproxy

# 5. Reload session
exec bash -l
```

---

### 5.3 Mobile Node Bootstrap (Android / Termux)
* **Perimeter:** Android Native File-Based Encryption (FBE).
* **Access:** Rootless Termux user-space.

```sh
# 1. Initialize Termux storage & bootstrap tools
termux-setup-storage
pkg update -y && pkg install -y git make curl

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and execute mobile build
./configure phone
make phone

# 4. Restore Vault from local storage
backup restore /sdcard/Download/vault-seed.tar.gz.age ~/.vault
vault chmod
vault apply ssh phone-sync

# 5. Reload session
exec bash -l
```

---

### 5.4 Pubnix Node Bootstrap (Shared Rootless UNIX)
* **Perimeter:** Shared multi-user environment.
* **Advisory:** Never deploy master identity keys to shared hosts. Stow only restricted, host-specific keys.

```sh
# 1. Connect to pubnix
ssh user@tilde.team

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and execute user-space build
./configure pubnix
make pubnix

# 4. Initialize isolated vault
vault init
vault apply pubnix-env
```

---

## 6. Daily Operator Workflows

### Synchronizing Private Vault State
Push or pull credentials and keys across machines natively:
```sh
vault sync
```

### Updating System Modules
When upstream public configurations change:
```sh
cd ~/projects/system
git pull --rebase
./configure <target>
make <target>
```

### Creating Encrypted Offsite Backups
Export a streaming `age`-encrypted archive before travel or maintenance:
```sh
backup create ~/.vault ~/backups/vault-$(date +%F).tar.gz.age
```

### Restoring from Cold Storage
Extract an offsite backup to any destination:
```sh
backup restore ~/backups/vault-2026-10-01.tar.gz.age ~/.vault
```
