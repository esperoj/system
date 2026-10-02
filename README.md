# System Architecture & Sovereign Node Specification

## 1. Meta-Directive & Core Philosophy

This computing environment is a personal sovereign system designed to remain understandable, buildable, and operable for decades without platform lock-in, vendor fatigue, or maintenance burden.

The system is pragmatic, not ideological.

Longevity, simplicity, safety, and flow are still the main goals, but when a pragmatic choice reduces real friction, avoids fragile workarounds, or lowers maintenance cost, that choice is accepted.

```text
FIRST PRINCIPLES                 DERIVED ARCHITECTURAL INVARIANTS
┌───────────────────────────┐    ┌───────────────────────────────────────────────┐
│ 1. Pragmatic Longevity    │───>│ Boring UNIX tooling; avoid fragile frameworks │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 2. Anti-Complexity        │───>│ Low cognitive overhead; inspectable text state│
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 3. Structural Safety      │───>│ Clear trust boundaries; explicit encryption   │
├───────────────────────────┤    ├───────────────────────────────────────────────┤
│ 4. Pragmatic Flow         │───>│ Immediate daily use; avoid recurring friction │
└───────────────────────────┘    └───────────────────────────────────────────────┘
```

---

### Axiom 1: Pragmatic Longevity

Code, formats, and tooling should remain readable and executable for decades.

Preferred foundations:

- POSIX shell
- GNU Make
- Git
- plain text
- GNU Stow
- standard UNIX utilities

Pragmatic allowances:

- Bash is allowed when it is clearer, more maintainable, or necessary.
- If a target environment lacks Bash but Bash is the pragmatic choice, install Bash rather than forcing awkward POSIX-only workarounds.
- GNU Make features are accepted when the supported baseline provides them.
- Hosted APIs are not forbidden. If a stable API is simpler and less fragile than scraping or custom workaround logic, using it is fine.

What is still avoided:

- ephemeral configuration frameworks
- overly abstract dotfile managers
- fragile package managers that constantly break on upstream changes
- unnecessary platform lock-in
- formats that cannot be inspected with normal text tools

---

### Axiom 2: Anti-Complexity

The operator should be able to hold the system state in their head and inspect it with standard utilities:

```sh
cat
ls
grep
find
git
make
```

Preferred state model:

- caches and build artifacts are disposable
- configuration state lives in flat text files
- generated state is small and replaceable
- no opaque databases for daily configuration

Pragmatic allowances:

- explicit supervised services are acceptable when a long-running process is genuinely required
- tools like `runit` are acceptable because they are small, explicit, and inspectable
- tmux remains an interactive tool, not a service manager

What is still avoided:

- hidden background state
- unmanaged daemon hacks
- complex service frameworks where a small supervisor is enough
- nested boilerplate that obscures what is actually deployed

---

### Axiom 3: Structural Safety

Resilience comes from clear boundaries and explicit operations.

Core safety model:

- full-disk encryption protects the local machine at rest
  - LUKS on Linux desktop
  - Android File-Based Encryption on Termux/Android
- cold offsite backups are encrypted with `age`
- encryption is applied explicitly when data crosses a network boundary
- permissions are enforced structurally where possible

Accepted personal tradeoffs:

- the private vault may sync to a trusted VPS unencrypted
- Docker images may use passwordless sudo when the container is a personal single-user environment
- binary downloads do not require mandatory checksum or signature verification unless the threat model changes

These tradeoffs are accepted because the alternative complexity is not worth the cost for a personal sovereign system.

---

### Axiom 4: Pragmatic Flow

Daily interactive tooling must be immediate, transparent, and low-friction.

Rules:

- shell login should be fast
- `.profile` should not perform package builds
- `.profile` should not run stow
- `.profile` should not prompt for decryption
- `.profile` should not make network calls
- daily Git work should be simple and tactile, preferably through Emacs Magit

Pragmatic allowances:

- a small amount of setup-time complexity is acceptable if it removes repeated daily friction
- explicit commands are preferred over magical automation
- if a choice makes the system easier to operate for years, it is preferred over theoretical purity

---

## 2. Accepted Pragmatic Tradeoffs

These choices are explicitly accepted.

| Area | Accepted Choice | Reason |
|---|---|---|
| GitHub API | GitHub REST API usage is fine when practical | Simpler and more reliable than brittle HTML scraping |
| Shell | Bash is allowed where useful | Better ergonomics and maintainability when POSIX sh becomes awkward |
| GNU Make | Modern GNU Make features are accepted | Primary targets are current Debian systems and future Debian releases |
| Alpine / FreeBSD | Potential future targets, not current priority | No need to carry compatibility complexity yet |
| Vault sync | Unencrypted vault sync to private VPS is accepted | Personal trust model; encrypted remote vault state adds too much pain |
| Docker sudo | Passwordless sudo inside personal container images is accepted | Single-user personal environment |
| Binary downloads | No mandatory checksum/signature verification by default | Personal threat model; may be revisited if needed |
| Emacs | System-provided packages preferred; no MELPA startup fetching | Offline-first and lower long-term fragility |
| Services | `runit` is preferred over tmux sessions for long-running services | Explicit supervision, restart behavior, and cleaner control |
| Termux | Use Termux packages where available | Avoid unnecessary binary fetching when the package manager is sufficient |

---

## 3. Implementation Derivation Matrix

| Architectural Component | Implementation Choice | Governing Principle | Rationale |
|---|---|---|---|
| Build engine | `./configure` + GNU Make | Pragmatic longevity | Native, boring, scriptable, and widely understood |
| State bus | flat-file `kv` store | Anti-complexity | Redis-inspired state without running a database daemon |
| Package delivery | apt / pkg / `fetch-bin` tiers | Pragmatic longevity | System packages where sensible, user-space binaries where needed |
| Binary fetcher | direct URLs, redirects, and GitHub REST API when practical | Pragmatic longevity | API use is accepted when it is simpler than scraping |
| Vault storage | unencrypted Git at `~/.vault` | Pragmatic safety | Local disk encryption is the main perimeter; personal VPS is trusted |
| Remote vault sync | bare Git repository over SSH | Anti-complexity | Native Git mechanics; no custom sync daemon |
| Dotfile linking | GNU Stow via `dot` wrapper | Anti-complexity | Standard symlinks, inspectable and removable |
| Offsite backups | streaming `tar | age` | Structural safety | Encryption applied explicitly when crossing network boundaries |
| Service supervision | `runit` when services are needed | Pragmatic flow | Explicit and rootless-capable; better than tmux service hacks |
| Emacs | built-ins plus system packages | Pragmatic flow | Offline-first, low moving-target dependency |

---

## 4. Subsystem Architecture

### 4.1 The State Bus: Flat `kv`

The `./configure` script probes the host node and populates `.kv-store`.

The `kv` tool is a flat-file key-value store inspired by Redis. It is not a full Redis implementation and does not attempt to speak the Redis wire protocol. Its purpose is simple declarative state for build and provisioning logic.

Storage scheme:

```text
.kv-store/strings/<key>
.kv-store/sets/<set_name>/<member>
.kv-store/hashes/<hash_name>/<field>
```

Design goals:

- no daemon
- no database file
- inspectable with `ls`, `cat`, `find`
- safe for bulk package batching
- line-oriented output for shell pipelines

Typical commands:

```sh
kv SET <key> <value>
kv GET <key>
kv DEL <key>

kv SADD <set> <member...>
kv SMEMBERS <set>
kv SREM <set> <member...>
kv SISMEMBER <set> <member>
kv SCARD <set>

kv HSET <hash> <field> <value>
kv HGET <hash> <field>
kv HKEYS <hash>

kv KEYS [pattern]
kv EXISTS <key>
```

Output conventions:

- `SMEMBERS` prints one member per line
- `KEYS` prints one key per line
- `MGET` prints one value per line
- missing `MGET` values are represented as empty lines
- exact Redis textual output is not a goal
- shell usability is the goal

Example:

```sh
install-sys-pkg $(kv SMEMBERS debian-pkgs)
```

---

### 4.2 The 3-Tier Package Delivery Engine

The system separates stable system packages from user-space binaries.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PACKAGE DELIVERY PIPELINE                       │
├──────────────────────────┬─────────────────────────┬───────────────────┤
│ Tier 1: Debian/Ubuntu    │ Tier 2: Android/Termux  │ Tier 3: Pubnix    │
│ Bulk apt-get             │ Bulk pkg install        │ fetch-bin         │
│ System infrastructure    │ User-space Termux env   │ ~/.local/bin      │
└──────────────────────────┴─────────────────────────┴───────────────────┘
```

Rules:

1. Use system packages when they are stable and sufficient.
2. Use Termux packages on Android/Termux when available.
3. Use `fetch-bin` for:
   - rootless environments
   - fast-moving tools
   - tools not packaged well by the system package manager
   - user-local installations under `~/.local/bin`

`fetch-bin` supports:

- direct HTTP/HTTPS URLs
- GitHub repositories using `gh:owner/repo`
- asset regex or pattern matching
- archive extraction for common formats
- installation into `~/.local/bin`

For GitHub releases, `fetch-bin` may use the GitHub REST API when that is simpler and more reliable than scraping HTML. This is accepted. Personal usage generally stays within reasonable API limits, and simplicity is preferred over ideological API avoidance.

---

### 4.3 Sovereign Vault (`~/.vault`)

Private keys, credentials, and sensitive configuration live in an unencrypted Git repository at:

```text
~/.vault
```

This is intentional.

Security model:

- local full-disk encryption is the primary perimeter
- the vault is kept unencrypted locally for speed and simplicity
- permissions are enforced automatically
- cold offsite backups are encrypted with `age`

Vault layout:

```text
~/.vault/
├── ssh/
├── rclone/
├── wireproxy/
├── _keys/
└── ...
```

Top-level directories are Stow packages unless explicitly prefixed as private non-stow storage.

Permission invariant:

```text
directories: 0700
files:       0600
executables: 0700
```

This is enforced by:

```sh
vault chmod
```

VPS synchronization:

```sh
vault sync
```

The remote repository is a bare Git repository on a private VPS:

```text
repos:srv/git/vault.git
```

The VPS copy is accepted as plaintext because it is a personal trusted system. If the threat model changes, remote encryption can be revisited.

---

### 4.4 Service Management

Long-running user services should be supervised explicitly.

Preferred supervisor:

```text
runit
```

Reasons:

- small
- stable
- explicit
- rootless-capable
- easy to inspect
- automatic restart on crash
- standard `up/down/status` control

Tmux is not treated as a service manager.

User-level layout:

```text
~/.config/sv/<service>/run
~/.service/<service> -> ~/.config/sv/<service>
~/.local/state/runit/
```

Control examples:

```sh
sv up ~/.service/wireproxy
sv down ~/.service/wireproxy
sv status ~/.service/wireproxy
```

Rootless behavior:

- user services can run without root
- privileged system services still require root or sudo
- SSH daemon control remains system-level
- user SSH tunnels can be supervised as a normal user

---

### 4.5 Emacs

Emacs is configured as a practical offline-first development environment.

Preferred foundations:

- built-in Emacs features
- `project.el`
- `eglot`
- `treesit` where practical
- Magit for Git workflows
- system-provided Emacs Lisp packages where possible

Avoided:

- MELPA fetching at startup
- network-dependent package installation as a core workflow
- fragile third-party package managers inside Emacs

If a package is needed, prefer:

1. built-in Emacs functionality
2. Debian/ELPA system package
3. Termux package
4. vendored file if truly necessary

---

## 5. Repository Layout

Primary layout:

```text
.
├── configure                     # Probe host and generate kv state
├── Makefile                      # Declarative build runner
├── Dockerfile                    # Container base image target
└── modules/
    ├── base/                     # Core dependencies
    ├── bin/                      # CLI tools: kv, dot, vault, fetch-bin, backup
    ├── crontab/                  # Cron table management
    ├── desktop/                  # Desktop environment config
    ├── dev/                      # Development tooling
    ├── emacs/                    # Emacs configuration
    ├── env/                      # Base environment files
    ├── lib/                      # Shared shell libraries
    ├── phone/                    # Termux/Android profile
    ├── pubnix/                   # Rootless shared UNIX profile
    ├── recipes/                  # Make recipes such as backup.mk
    ├── shell/                    # .profile, .bashrc, .inputrc
    ├── ssh/                      # Public SSH material
    ├── stow/                     # GNU Stow bootstrap
    ├── sys-pkgs/                 # System package batching
    ├── vault/                    # Vault setup hooks
    └── wireproxy/                # WireProxy configuration
```

---

## 6. Node Commissioning & Bootstrap Manual

### 6.1 Preparing the Trust Root

A new node cannot pull its cryptographic identity out of thin air.

Choose one trust root:

#### Method A: Networked / SSH Agent

If setting up remotely from an existing machine:

```sh
ssh -A user@new-node
```

#### Method B: Offline / Cold Seed

Create an encrypted vault archive from an established node:

```sh
backup create ~/.vault ~/vault-seed.tar.gz.age
```

Transfer:

- `vault-seed.tar.gz.age`
- your `age` identity key

to the target machine using USB or another local transfer method.

---

### 6.2 Desktop Node Bootstrap

Target:

- Debian desktop
- LUKS full-disk encryption
- normal user with sudo

```sh
# 1. Install bootstrap dependencies
sudo apt-get update && sudo apt-get install -y git make curl ca-certificates

# 2. Clone system repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and build
./configure desktop
make desktop

# 4. Provision vault
# Option A: SSH identity
mkdir -p ~/.ssh && chmod 700 ~/.ssh
cp /path/to/id_ed25519 ~/.ssh/id_ed25519 && chmod 600 ~/.ssh/id_ed25519
vault init repos:srv/git/vault.git

# Option B: cold backup
backup restore /path/to/vault-seed.tar.gz.age ~/.vault
vault chmod
vault apply ssh rclone wireproxy

# 5. Reload session
exec bash -l
```

---

### 6.3 Mobile Node Bootstrap

Target:

- Android
- Termux
- Android File-Based Encryption

```sh
# 1. Initialize storage and bootstrap tools
termux-setup-storage
pkg update -y && pkg install -y git make curl

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and build
./configure phone
make phone

# 4. Restore vault
backup restore /sdcard/Download/vault-seed.tar.gz.age ~/.vault
vault chmod
vault apply ssh phone-sync

# 5. Reload session
exec bash -l
```

---

### 6.4 Pubnix Node Bootstrap

Target:

- shared rootless UNIX host
- no master identity keys unless explicitly required

Advisory:

> Never deploy master identity keys to shared hosts unless you fully trust the host and understand the consequences.

```sh
# 1. Connect to pubnix host
ssh user@tilde.team

# 2. Clone repository
mkdir -p ~/projects
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system

# 3. Configure and build
./configure pubnix
make pubnix

# 4. Initialize isolated vault
vault init
vault apply pubnix-env
```

---

## 7. Daily Operator Workflows

### Synchronize Vault

```sh
vault sync
```

---

### Update System Modules

```sh
cd ~/projects/system
git pull --rebase
./configure <target>
make <target>
```

---

### Create Encrypted Offsite Backup

```sh
backup create ~/.vault ~/backups/vault-$(date +%F).tar.gz.age
```

---

### Restore From Cold Storage

```sh
backup restore ~/backups/vault-2026-10-01.tar.gz.age ~/.vault
```

---

### Manage User Services

For runit-managed services:

```sh
sv status ~/.service/<service>
sv up ~/.service/<service>
sv down ~/.service/<service>
```

Examples:

```sh
sv up ~/.service/wireproxy
sv down ~/.service/wireproxy
sv status ~/.service/wireproxy
```

---

## 8. Supported Targets

Primary current targets:

- Debian desktop
- Termux phone
- Docker base environment
- personal pubnix hosts

Potential future targets:

- Alpine
- FreeBSD

Alpine and FreeBSD are not active compatibility targets right now. Compatibility complexity for them is intentionally avoided until there is a real need.
