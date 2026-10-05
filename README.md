# Sovereign Computing Environment & Node Specification

## 1. Meta-Directive & Core Philosophy

This computing environment is a personal sovereign system designed to remain understandable, buildable, and operable for decades without platform lock-in, vendor fatigue, or maintenance burden.

The system is pragmatic, not ideological.

Longevity, simplicity, safety, and flow are the primary constraints. When a pragmatic choice reduces real friction, avoids fragile abstractions, or lowers long-term maintenance cost, that choice is accepted.

```text
FIRST PRINCIPLES                 DERIVED ARCHITECTURAL INVARIANTS
┌───────────────────────────┐    ┌───────────────────────────────────────────────┐
│ 1. Pragmatic Longevity    │───>│ Plain GNU Make & POSIX sh; no framework churn │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 2. Anti-Complexity        │───>│ In-memory Make DAG; no state daemon/flat DB  │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 3. Structural Safety      │───>│ Explicit permissions; offline-first bootstrap │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 4. Pragmatic Flow         │───>│ Immediate execution; single-command handoff   │
└───────────────────────────┘    └───────────────────────────────────────────────┘
```

---

### Axiom 1: Pragmatic Longevity

Code, formats, and tooling must remain readable and executable for decades.

Preferred foundations:
- POSIX shell
- GNU Make
- Git
- Plain text
- GNU Stow
- Standard UNIX utilities

What is avoided:
- Ephemeral configuration frameworks
- Complex dotfile engines with non-standard DSLs
- Unnecessary daemon layers for state storage
- Formats that cannot be inspected with standard text utilities (`cat`, `find`, `grep`)

---

### Axiom 2: Anti-Complexity

The operator should be able to hold the entire build model in memory:
- **No external state database:** No Redis, no bespoke flat-file state buses. System state lives directly in the filesystem and within the GNU Make dependency graph.
- **Single-phase evaluation:** No awkward multi-phase configure dances. Targets evaluate on demand in a single invocation.
- **Disposable cache:** Ephemeral state is restricted strictly to the `.state/` directory and can be purged at any moment without corrupting the repository.

---

### Axiom 3: Structural Safety

Resilience comes from clear boundaries, explicit dependencies, and offline survivability:
- **Offline-first bootstrap:** System bootstrap does not assume active network access or established SSH keys.
- **Local perimeter security:** Full-disk encryption (LUKS on desktop, Android FBE on mobile) protects data at rest.
- **Strict permissions:** Private credentials and keys are programmatically clamped to `0700` (directories/executables) and `0600` (files).
- **Transport encryption:** Offsite backups are streamed through `tar | age`.

---

### Axiom 4: Pragmatic Flow

Daily interactive tooling must be immediate, transparent, and low-friction:
- Shell startup (`.profile`, `.bashrc`) performs zero package compilation, network calls, or stow linking.
- Fast, cached, idempotent builds: if configuration has not changed, running a target finishes in milliseconds.
- Standalone CLI utilities: scripts like `install-sys-pkg` and `fetch-bin` work directly from the terminal without requiring Make orchestration.

---

## 2. Architecture & Invariants

```text
┌────────────────────────────────────────────────────────┐
│ MAKE LAYER (OS-Agnostic Graph & Set Accumulation)      │
│                                                        │
│  - Goal inclusion: make desktop -> desktop.mk          │
│  - Include guards: ifndef MOD_GIT                      │
│  - Set accumulation: COMMON_PKGS += ..., DEBIAN_PKGS +=│
│  - Dependency graph: emacs: sys-pkgs git stow          │
│  - Cache invalidation: .state/sys-pkgs.stamp           │
└───────────────────────────┬────────────────────────────┘
                            │ export COMMON_PKGS DEBIAN_PKGS ...
                            ▼
┌────────────────────────────────────────────────────────┐
│ SHELL SCRIPT LAYER (Host-Aware Execution)              │
│                                                        │
│  - install-sys-pkg: sources os.sh                      │
│  - Standalone CLI: install-sys-pkg ripgrep fd-find     │
│  - Batch Mode: install-sys-pkg (reads exported vars)   │
└────────────────────────────────────────────────────────┘
```

### 2.1 Pure Make DAG & Goal-Driven Includes

The build system relies on native GNU Make Directed Acyclic Graphs (DAG) and in-memory set accumulation:
1. When invoking `make <target>`, Make includes only `modules/<target>/<target>.mk`.
2. Target modules recursively pull their dependencies via `include` directives protected by `ifndef MOD_<NAME>` include guards.
3. Modules not in the target's dependency tree are never parsed. Their packages never leak into the build.
4. Duplicate dependencies evaluate exactly once, preserving parallel build safety under `-j`.

### 2.2 Distro Package Accumulation (Zero-Condition Declarations)

Modules do not contain repetitive `ifeq ($(DISTRO),...)` blocks. They append package requirements to flat, distro-specific variables:

```makefile
COMMON_PKGS += pandoc
DEBIAN_PKGS += emacs-gtk elpa-magit
TERMUX_PKGS += emacs
```

The root `Makefile` exports these variables to subprocesses.

### 2.3 The `sys-pkgs` Barrier & Cache Invalidation

System package installation is governed by a hidden stamp file:

```makefile
$(STATE_DIR)/sys-pkgs.stamp: $(MAKEFILE_LIST)
	@mkdir -p $(STATE_DIR)
	@install-sys-pkg
	@touch $@

.PHONY: sys-pkgs
sys-pkgs: $(STATE_DIR)/sys-pkgs.stamp
```

- **Self-Healing Timestamp Checking:** `.state/sys-pkgs.stamp` depends directly on `$(MAKEFILE_LIST)`. If any loaded module file is edited, Make detects the newer timestamp and executes `install-sys-pkg`.
- **Instant No-Op:** If no module makefile has changed, `sys-pkgs` resolves in 0.001 seconds.
- **Explicit Target Prerequisites:** Modules explicitly declare `sys-pkgs` (e.g., `emacs: sys-pkgs git stow`), guaranteeing packages exist before dotfiles are linked or scripts are run.

---

## 3. Package Delivery Subsystem

### 3.1 `install-sys-pkg` (Dual-Mode Installer)

The system package delivery tool operates in two distinct modes:

1. **Batch Mode (Called by Make):**
   Invoked with no arguments. It auto-detects `$DISTRO` via `os.sh`, resolves the matching `$DEBIAN_PKGS`, `$TERMUX_PKGS`, or `$ALPINE_PKGS` set alongside `$COMMON_PKGS`, deduplicates the union, and runs the package manager.
2. **Standalone Mode (Interactive CLI):**
   Invoked with arguments directly by the operator:
   ```sh
   install-sys-pkg ripgrep tmux fzf
   ```
   It auto-detects the host distro and executes the underlying package manager (`apt-get`, `pkg`, `apk`, or BSD `pkg`) with privilege escalation where appropriate.

### 3.2 `fetch-bin` (User-Space Binary Fallback)

Used for rootless environments (Pubnix), fast-moving CLI tools, or packages missing from base distribution repositories:
- Direct HTTP/HTTPS URLs.
- GitHub releases via `gh:owner/repo` pattern matching.
- Automatic archive extraction (`tar.gz`, `tar.xz`, `tar.zst`, `zip`, `bz2`).
- Installs standalone executables directly to `~/.local/bin`.

---

## 4. Sovereign Vault Subsystem (`~/.vault`)

Sensitive configurations, private credentials, and personal keys reside in an unencrypted Git repository at:

```text
~/.vault/
```

### 4.1 Solving the SSH Chicken-and-Egg Dilemma

On a fresh node, you cannot clone `~/.vault` over SSH because the SSH private key required to authenticate against the server is stored *inside* the vault itself.

`modules/vault/setup` handles this structurally:

1. **Raw Seed / Cold Backup (Recommended for new nodes):**
   Unpack a cold backup archive into `~/.vault`:
   ```sh
   backup restore /path/to/vault-seed.tar.gz.age ~/.vault
   ```
   When `make vault` or `make desktop` runs, `vault/setup` detects raw files without `.git`, initializes a local repository (`git -C ~/.vault init -b main`), attaches the remote `origin`, locks permissions, and applies dotfiles. **Zero network calls are made.**
2. **Existing Clone:**
   If `~/.vault/.git` is present, it updates the remote URL, enforces permissions, and applies modules.
3. **Network Clone:**
   If `~/.vault` is empty and SSH credentials are provided (e.g., via agent forwarding `ssh -A`), it clones from the remote VPS.

### 4.2 Permission Enforcement

All vault files are programmatically locked to prevent permission leaks:
- Directories: `0700`
- Regular files: `0600`
- Executable files: `0700`

Manual enforcement:
```sh
vault chmod
```

### 4.3 Applying Vault Modules

Profiles declare the vault modules they require using standard variable accumulation:

```makefile
VAULT_MODULES += ssh base git rclone
```

`vault/setup` reads `$VAULT_MODULES` directly from the environment and executes `vault apply <mod>` via GNU Stow.

---

## 5. Repository Layout

```text
.
├── bootstrap                     # Zero-to-Make minimal host primer
├── Makefile                      # Dynamic DAG builder and package orchestrator
├── Dockerfile                    # Debian 13-slim container specification
├── .state/                       # Ephemeral build stamps and state (git-ignored)
└── modules/
    ├── base/                     # Core OS dependencies, recipes, and utilities
    ├── bin/                      # System binaries: dot, install-sys-pkg, backup, vault, fetch-bin
    ├── crontab/                  # Automated scheduled maintenance
    ├── desktop/                  # Debian desktop GUI node profile
    ├── dev/                      # Compilers, linters, shells, and editor tools
    ├── docker-base/              # Container base environment profile
    ├── emacs/                    # Offline-first GNU Emacs IDE
    ├── env/                      # Base environment variables (~/.config/env)
    ├── lib/                      # Shared shell libraries (os.sh, fetch.sh)
    ├── phone/                    # Termux mobile node profile
    ├── pubnix/                   # Rootless shared UNIX node profile
    ├── recipes/                  # Standalone maintenance Makefiles (backup.mk)
    ├── shell/                    # .bashrc, .profile, .inputrc
    ├── ssh/                      # Public SSH keys and configurations
    ├── stow/                     # GNU Stow bootstrap and wrappers
    ├── vault/                    # Sovereign vault setup hooks
    └── wireproxy/                # Wireguard userspace proxy
```

Each module is self-contained:

```text
modules/<name>/
├── <name>.mk                     # Declarative rules, packages, and include guards
├── dotfiles/                     # Files symlinked to target by GNU Stow
└── install                       # User-space binary fetcher script (if needed)
```

---

## 6. Node Commissioning Manual

### 6.1 Preparing the Trust Root

Choose one of two root-of-trust bootstrap paths:

#### Path A: Cold Seed (Offline / Air-Gapped)
On an existing authorized machine, create an encrypted vault backup:
```sh
backup create ~/.vault ~/vault-seed.tar.gz.age
```
Transfer `vault-seed.tar.gz.age` and your `age` secret key to the target node via USB.

#### Path B: SSH Agent Forwarding (Remote Provisioning)
Connect to the clean node while forwarding your active SSH agent:
```sh
ssh -A user@target-node
```

---

### 6.2 Desktop Node (Debian 13+)

Target: Physical workstation, LUKS encryption, non-root user with `sudo`.

```sh
# 1. Unpack or clone system repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 2. If bootstrapping via Cold Seed: restore vault files before running make
backup restore /path/to/vault-seed.tar.gz.age ~/.vault

# 3. Prime host and deploy desktop profile in one step
./bootstrap desktop

# 4. If bootstrapping via SSH Agent Forwarding (no cold seed used):
# Initialize vault from remote bare repo
vault init repos:srv/git/vault.git
make vault

# 5. Reload session
exec bash -l
```

---

### 6.3 Mobile Node (Android / Termux)

Target: Android device, Termux user-space environment.

```sh
# 1. Initialize Termux storage
termux-setup-storage

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Restore cold vault backup from shared storage
backup restore /sdcard/Download/vault-seed.tar.gz.age ~/.vault

# 4. Prime host and deploy phone profile
./bootstrap phone

# 5. Reload session
exec bash -l
```

---

### 6.4 Container Node (Docker Base)

Target: Minimal headless Debian 13 container.

Build image:
```sh
docker build -t system:base .
```

Run container:
```sh
docker run -it --rm system:base
```

The container automatically invokes `./bootstrap docker-base`, prunes APT recommends and cache, and sets up a non-root sovereign environment.

---

### 6.5 Pubnix Node (Shared Rootless UNIX)

Target: Multi-user tilde server, no root access.

```sh
# 1. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 2. Bootstrap pubnix profile (runs user-space stow, skips sudo apt)
./bootstrap pubnix

# 3. Reload session
exec bash -l
```

---

## 7. Daily Operator Workflows

### Target Execution & Updates

Deploy or update profiles:
```sh
cd ~/projects/system
git pull --rebase
make desktop        # Or: make phone, make docker-base, make pubnix
```

Deploy or test an isolated submodule:
```sh
make emacs
make git
make dev
```

Inspect the dry-run execution graph:
```sh
make -n desktop
```

---

### Package Cache Management

Force a complete re-evaluation and reinstallation of system packages:
```sh
make clean-state
make desktop
```

Install an ad-hoc system package outside of Make:
```sh
install-sys-pkg ripgrep
```

---

### Sovereign Vault Operations

Synchronize uncommitted vault state with the trusted private VPS:
```sh
vault sync
```

Inspect vault status and module links:
```sh
vault status
```

Enforce strict 600/700 permissions:
```sh
vault chmod
```

Spawn a subshell inside the vault:
```sh
vault cd
```

---

### Encrypted Cold Backups

Create a streaming encrypted archive of the vault:
```sh
backup create ~/.vault ~/backups/vault-$(date +%F).tar.gz.age
```

Restore an encrypted archive:
```sh
backup restore ~/backups/vault-2026-10-05.tar.gz.age ~/.vault
```

---

### Code Quality & Maintenance

Verify shell scripts with ShellCheck and shfmt:
```sh
make lint
```

Format all repository shell scripts in place:
```sh
make fmt
```

Run an automated design review using Aider:
```sh
make review
```
