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
- GNU Stow (`--no-folding`)
- Standard UNIX utilities

What is avoided:
- Ephemeral configuration frameworks
- Complex dotfile engines with bespoke DSLs
- Unnecessary daemon layers for state storage
- Formats that cannot be inspected with standard text utilities (`cat`, `find`, `grep`)

---

### Axiom 2: Anti-Complexity

The operator should be able to hold the entire build model in memory:
- **No external state database:** System state lives directly in the filesystem and within the GNU Make dependency graph.
- **Single-phase evaluation:** Targets evaluate on demand in a single invocation.
- **Disposable cache:** Ephemeral state is restricted strictly to the `.state/` directory and can be purged at any moment without corrupting the repository.

---

### Axiom 3: Structural Safety

Resilience comes from clear boundaries, explicit dependencies, and offline survivability:
- **Offline-first bootstrap:** System bootstrap does not assume active network access or established SSH keys.
- **Strict permissions:** Private credentials and keys are programmatically locked to `0700` (directories/executables) and `0600` (files).
- **Separation of concerns:** Public configurations live in the system repository; private keys and secrets reside in `~/.vault/`.

---

### Axiom 4: Pragmatic Flow

Daily interactive tooling must be immediate, transparent, and low-friction:
- Shell startup (`.profile`, `.bashrc`) performs zero package compilation, network calls, or stow linking.
- Fast, cached, idempotent builds: if configuration has not changed, running a target finishes in milliseconds.
- Standalone CLI utilities: scripts like `dot`, `vault`, `install-sys-pkg`, and `fetch-bin` work directly from the terminal without requiring Make orchestration.

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
│  - Cache invalidation: $(STATE_DIR)/sys-pkgs.stamp     │
└───────────────────────────┬────────────────────────────┘
                            │ export COMMON_PKGS DEBIAN_PKGS ...
                            ▼
┌────────────────────────────────────────────────────────┐
│ SHELL SCRIPT LAYER (Host-Aware Execution)              │
│                                                        │
│  - install-sys-pkg: sources os.sh                      │
│  - dot: applies modules into $HOME via Stow            │
│  - vault: manages ~/.vault permissions and syncing     │
└────────────────────────────────────────────────────────┘
```

### 2.1 Pure Make DAG & Goal-Driven Includes

The build system relies on native GNU Make Directed Acyclic Graphs (DAG) and in-memory set accumulation:
1. When invoking `make <target>`, Make includes only `modules/<target>/<target>.mk`.
2. Target modules recursively pull their dependencies via `include` directives protected by `ifndef MOD_<NAME>` include guards.
3. Modules not in the target's dependency tree are never parsed; their package declarations never enter the build.
4. Duplicate dependencies evaluate exactly once, preserving parallel build safety under `-j`.

### 2.2 Distro Package Accumulation (Zero-Condition Declarations)

Modules do not contain repetitive conditional blocks. They append package requirements to flat, distro-specific variables:

```makefile
COMMON_PKGS += ripgrep tmux
DEBIAN_PKGS += emacs-gtk elpa-magit
TERMUX_PKGS += emacs
```

The root `Makefile` exports these variables to subprocesses.

### 2.3 The `sys-pkgs` Barrier & Self-Healing Cache

System package installation is governed by a hidden stamp file:

```makefile
$(STATE_DIR)/sys-pkgs.stamp: $(MAKEFILE_LIST)
	@mkdir -p $(STATE_DIR)
	@install-sys-pkg
	@touch $@

.PHONY: sys-pkgs
sys-pkgs: $(STATE_DIR)/sys-pkgs.stamp
```

- **Automatic Invalidation:** `.state/sys-pkgs.stamp` depends on `$(MAKEFILE_LIST)`. If any loaded module file is edited, Make detects the newer timestamp and executes `install-sys-pkg`.
- **Instant No-Op:** If no module makefile has changed, `sys-pkgs` resolves in 0.001 seconds.
- **Explicit Target Prerequisites:** Modules declare `sys-pkgs` before stowing files or running build steps.

---

## 3. Package Delivery Subsystem

### 3.1 `install-sys-pkg` (Dual-Mode Installer)

The system package delivery tool operates in two distinct modes:

1. **Batch Mode (Orchestrated by Make):**
   Invoked with no arguments. It auto-detects `$DISTRO` via `os.sh`, resolves the matching `$DEBIAN_PKGS`, `$TERMUX_PKGS`, `$ALPINE_PKGS`, or `$FREEBSD_PKGS` set alongside `$COMMON_PKGS`, deduplicates the union, and runs the system package manager.
2. **Standalone Mode (Interactive CLI):**
   Invoked with package names directly by the operator:
   ```sh
   install-sys-pkg ripgrep tmux fzf
   ```
   It auto-detects the host distro and executes the underlying package manager (`apt-get`, `pkg`, or `apk`) with privilege escalation where appropriate.

### 3.2 `fetch-bin` (User-Space Binary Fallback)

Used for rootless environments (Pubnix), fast-moving CLI tools, or packages missing from base distribution repositories:
- Direct HTTP/HTTPS URLs.
- GitHub releases via `gh:owner/repo` pattern matching.
- Automatic archive extraction (`tar.gz`, `tar.xz`, `tar.zst`, `zip`, `bz2`).
- Installs standalone executables directly to `~/.local/bin`.

---

## 4. Dotfile Management Subsystem (`dot`)

The `dot` CLI wraps GNU Stow with safe pre-flight conflict resolution and concurrency locking.

### 4.1 Structural Rules

- **Native `--no-folding`:** Stow is strictly executed with `--no-folding`. Directories in `$HOME` (such as `~/.config/autostart` or `~/.ssh`) are always real directories, never symlinks. Only individual leaf files are symlinked.
- **Conflict Handling:**
  - **Unmanaged Host Files:** If an unmanaged real file (such as a default `/etc/skel/.bashrc`) blocks a link, `dot` moves it to `~/.local/state/dot/backup/` before Stow runs.
  - **Stale or Overridden Symlinks:** If an existing symlink points elsewhere, it is unlinked (`rm -f`) so Stow can point it to the active module.
  - **Shared Directories:** Multiple modules can safely place files in the same directory (e.g. `desktop` and `vault` both placing desktop entries in `~/.config/autostart/`) without colliding.

### 4.2 CLI Usage

```sh
# Apply module(s) from current or specified MODULES_DIR
dot apply <module...>

# Unlink module(s)
dot remove <module...>

# List available modules
dot ls
```

---

## 5. Sovereign Vault Subsystem (`~/.vault`)

Private configurations, SSH keys, credentials, and machine-specific secrets reside in an unencrypted Git repository at:

```text
~/.vault/
```

### 5.1 Architecture & Separation

The vault mirrors the modular layout of the system repository:

```text
~/.vault/
├── ssh/                      # ~/.ssh/id_ed25519, config
├── git/                      # ~/.gitconfig (private signing keys/email)
├── rclone/                   # ~/.config/rclone/rclone.conf
└── base/                     # Core private configurations
```

### 5.2 Permission Enforcement

All vault files are programmatically locked to prevent permission leaks:
- Directories: `0700`
- Executable files: `0700`
- Regular files: `0600`

Permission clamping runs automatically on `vault apply`, `vault sync`, and can be triggered manually via:
```sh
vault chmod
```

### 5.3 Automated Profile Integration

Profiles declare the vault modules they require using standard variable accumulation:

```makefile
VAULT_MODULES += ssh base git rclone
```

When `make vault` or `make base` runs, `modules/vault/vault.mk` reads `$VAULT_MODULES` and executes `vault apply $(VAULT_MODULES)`.

### 5.4 CLI Usage

```sh
# Initialize new vault or attach remote origin
vault init [remote-git-url]

# Commit all changes, rebase from upstream, and push
vault sync

# Apply modules to $HOME (clamps 600/700 permissions and runs dot apply)
vault apply <module...>

# Unlink vault modules
vault remove <module...>

# Enforce strict 600/700 permissions across the vault tree
vault chmod

# List available modules in ~/.vault
vault ls

# Direct Git pass-through inside ~/.vault
vault git status
vault git diff
vault git log
```

---

## 6. Repository Layout

```text
.
├── bootstrap                     # Zero-to-Make minimal host primer
├── Makefile                      # Dynamic DAG builder and package orchestrator
├── Dockerfile                    # Debian 13-slim container specification
├── .state/                       # Ephemeral build stamps and state (git-ignored)
└── modules/
    ├── base/                     # Core OS dependencies, recipes, and utilities
    ├── bin/                      # System binaries: dot, install-sys-pkg, vault, fetch-bin
    ├── crontab/                  # Scheduled maintenance configurations
    ├── desktop/                  # Debian desktop GUI node profile
    ├── dev/                      # Compilers, linters, shells, and editor tools
    ├── docker-base/              # Container base environment profile
    ├── emacs/                    # Offline-first GNU Emacs IDE
    ├── env/                      # Base environment variables (~/.config/env)
    ├── lib/                      # Shared shell libraries (os.sh, fetch.sh)
    ├── phone/                    # Termux mobile node profile
    ├── pubnix/                   # Rootless shared UNIX node profile
    ├── recipes/                  # Maintenance recipes
    ├── shell/                    # .bashrc, .profile, .inputrc
    ├── ssh/                      # Public SSH configurations and keys
    ├── stow/                     # GNU Stow bootstrap and wrappers
    ├── vault/                    # Sovereign vault integration hooks
    └── wireproxy/                # WireGuard userspace proxy
```

Each module is self-contained:

```text
modules/<name>/
├── <name>.mk                     # Declarative rules, packages, and include guards
├── dotfiles/                     # Files symlinked to target by dot
└── install                       # Binary fetcher script (if needed)
```

---

## 7. Node Commissioning Manual

### 7.1 Desktop Node (Debian 13+)

Target: Physical workstation, LUKS encryption, non-root user with `sudo`.

```sh
# 1. Clone system repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 2. Prime host and deploy desktop profile
./bootstrap desktop

# 3. Initialize vault (if not already present)
vault init <VAULT_REPO_URL>
make vault

# 4. Reload session
exec bash -l
```

---

### 7.2 Mobile Node (Android / Termux)

Target: Android device, Termux user-space environment.

```sh
# 1. Initialize Termux storage
termux-setup-storage

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Prime host and deploy phone profile
./bootstrap phone

# 4. Initialize vault (if not already present)
vault init <VAULT_REPO_URL>
make vault

# 5. Reload session
exec bash -l
```

---

### 7.3 Container Node (Docker Base)

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

### 7.4 Pubnix Node (Shared Rootless UNIX)

Target: Multi-user shared server, no root access.

```sh
# 1. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 2. Bootstrap pubnix profile (runs user-space stow, skips sudo apt)
./bootstrap pubnix

# 3. Initialize vault
vault init <VAULT_REPO_URL>
make vault

# 4. Reload session
exec bash -l
```

---

## 8. Daily Operator Workflows

### Target Execution & Updates

Deploy or update entire profiles:
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

Synchronize uncommitted vault state with the remote Git server:
```sh
vault sync
```

Inspect vault status and module links:
```sh
vault git status
vault ls
```

Enforce strict 600/700 permissions manually:
```sh
vault chmod
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

Run an automated design review on the latest commit:
```sh
make review
```
