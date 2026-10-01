# System Architecture & Core Specification

## Meta-Directive for AI Refactoring Agents

This document defines the canonical target specification for this repository. It serves as an authoritative instruction set for refactoring, pruning, and maintaining the codebase.

Any automated agent or operator modifying this repository must enforce the following refactoring rules:

1. **Eliminate Fossil Code:** Remove all references, scripts, or hooks related to Fossil (`fossil new`, `.fossil-settings`, etc.). All version control strictly uses **Git**.
2. **Consolidate Package Installers:** Remove redundant package management wrappers (`setup`, `install-archive`, `install-sys-pkg`, `pkg-install`). Package discovery and installation must be routed strictly through `./configure` and `Makefile` utilizing the `kv` store.
3. **Prune Cloud Infrastructure Drivers:** Strip unnecessary deployment targets from `run-command` or auxiliary scripts. Limit remote triggers exclusively to primary git remotes.
4. **Remove Session Encryption Wrappers:** Deprecate RAMFS mounts and runtime Age decryption inside `vault`. Treat host disk encryption (LUKS / Android FBE) as the security boundary for local session work.

---

## Core Philosophy & Guiding Principles

This computing environment is a personal sovereign system built to last for decades without technical debt, platform lock-in, or maintenance fatigue.

### General Philosophy

* **Longevity & Future-Proofing:** Code and data formats are chosen to be readable and executable 30 years from now. Software dependencies are kept strictly to ubiquitous UNIX standards.
* **Simplicity & Anti-Complexity Bias:** Prefer the simplest primitive that works. Avoid abstraction layers, complex runtimes, and unnecessary service daemons.
* **Safety & Resilience:** Resilience comes from structural simplicity, human-inspectable states, atomic ops, and bulletproof offline backups—not complex automated recovery frameworks.
* **Maintainability & Operator Sovereignty:** The system must be fully understandable and maintainable by a single operator without third-party services or cloud dependencies.

### Technical Implementation Principles

* **Files as Canonical Source of Truth:** Plain text files (`.json`, `.md`, POSIX shell, standard configurations) store authoritative state.
* **Disk-Level Encryption Boundary:** Security at rest relies on full-disk encryption (LUKS on Linux, File-Based Encryption on Android). Runtime file encryption layers are eliminated to optimize daily ergonomics and tooling integration.
* **Rebuildable Derived State:** Caches, build artifacts, and query indexes (e.g., SQLite database indexes derived from JSON catalogs) are disposable and 100% rebuildable from canonical state.
* **80/20 Mental Model & Low Dependency Count:** Achieve 80% of functionality with 20% of the complexity. Core tooling stack is strictly limited to POSIX shell, `make`, `git`, `sqlite`, `emacs`, and standard UNIX CLI tools.

---

## Evaluation of the Build Pipeline (`configure` + `Makefile`)

The current `configure` and `Makefile` architecture is **fully optimal** and directly aligns with the system philosophy.

* **Why it works:** It avoids heavy automation tools (Ansible, Docker engines, Nix, Python setup scripts) in favor of standard UNIX tooling present on both minimal Linux and Termux nodes.
* **How it operates:** `./configure` acts as a lightweight, zero-dependency POSIX probe that identifies node parameters (Debian Linux vs. Android Termux) and populates `.kv-store`. The `Makefile` then declaratively executes environment configuration, package installation, and dotfile linking (`stow`) by querying `kv`.

---

## Core Subsystem Specifications

### 1. Key-Value Store (`kv`) — Redis-Inspired Flat-File CLI

The `kv` utility (`modules/bin/kv`) provides a Redis-inspired key-value interface implemented in POSIX shell operating on a plain-text backing file (`.kv-store`).

#### Supported Commands & Behavior

* `kv SET <key> <value>` — Sets a key to a string value.
* `kv GET <key>` — Prints the value of a key.
* `kv DEL <key>` — Removes a key entry.
* `kv KEYS [pattern]` — Lists matching keys (defaults to `*`).
* `kv EXISTS <key>` — Returns exit status `0` if key exists, `1` otherwise.
* `kv APPEND <key> <value>` — Appends a value to a space-separated string array at `<key>`.
* `kv HSET <hash> <field> <value>` — Sets a field within a field-value hash map.
* `kv HGET <hash> <field>` — Retrieves a field value from a hash map.

### 2. Vault Subsystem (`vault`) — Unencrypted Private Git

Sensitive configuration files, private keys, and personal credentials reside in an unencrypted private Git repository on disk.

* **Path:** `~/.vault`
* **Security Boundary:** Protected at rest by host-level encryption (LUKS on Linux, FBE on Android). Protected in transit via SSH.
* **Tooling Integration:** Works directly with native Git tools (`git`, `magit`, `fzf`, `rg`, standard editors) without decrypting/encrypting steps during active sessions.

### 3. Cold Storage & Offsite Backup (`backup`)

Cold storage archives enforce explicit streaming `age` encryption before exiting the node security boundary.

* **Backup Command:** `backup create <source_dir> <output_file.tar.gz.age>`
* *Implementation:* `tar -czf - -C <parent_dir> <target> | age -r <public_key> > <output_file.tar.gz.age>`


* **Restore Command:** `backup restore <input_file.tar.gz.age> <destination_dir>`
* *Implementation:* `age -d -i <private_key_file> <input_file.tar.gz.age> | tar -xzf - -C <destination_dir>`



---

## Multi-Node Specification & Parity

The system operates uniformly across desktop/server nodes and mobile nodes.

| Feature | Linux Node (Debian/XFCE) | Mobile Node (Android/Termux) |
| --- | --- | --- |
| **Disk Encryption** | LUKS (dm-crypt) | Android Native File-Based Encryption (FBE) |
| **Environment** | Standard POSIX / Bash | Termux POSIX Environment |
| **Package Management** | `apt-get` | `pkg` |
| **Version Control** | Git / Git-Annex | Git / Git-Annex |
| **Private State** | Unencrypted Git (`~/.vault`) | Unencrypted Git (`~/.vault`) |
| **Primary Interfaces** | CLI / XFCE / Emacs | CLI / Termux / Emacs |

---

## Repository Layout

```text
.
├── configure                 # POSIX node probe and kv store generator
├── Makefile                  # Master declarative build driver
├── docs/                     # Architectural specs and documentation
├── modules/
│   ├── bin/                  # POSIX scripts (kv, vault, backup, dot)
│   ├── dotfiles/             # Stow-compatible configuration trees
│   └── packages/             # Package manifests for Debian and Termux
└── store/                    # Canonical data stores & git-annex pointers

```

---

## Implementation Workflows

### Node Setup & Bootstrap

```sh
./configure
make setup
make dot

```

### Key-Value State Management

```sh
kv SET node.arch "x86_64"
kv APPEND sys.packages "emacs git sqlite3 tmux"
kv HSET user:config email "user@domain.com"

kv GET sys.packages
kv HGET user:config email

```

### Vault Synchronization

```sh
cd ~/.vault
git add .
git commit -m "Update private configuration"
git push origin main

```

### Cold Encrypted Backup

```sh
# Create age-encrypted tar archive of ~/.vault
backup create ~/.vault ~/backups/vault-$(date +%F).tar.gz.age

# Restore backup
backup restore ~/backups/vault-2026-10-01.tar.gz.age ~/restored-vault

```
