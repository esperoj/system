Rewritten README below. The rule I applied throughout: every absolute claim from the old version ("offline-first", implied POSIX purity) is either now actually true, or explicitly declared as a bend with the reason. No aspiration left in the document — only behavior.

````markdown
# Sovereign Computing Environment & Node Specification

## 1. Purpose & Philosophy

This is a personal sovereign system designed to remain understandable,
buildable, and operable for decades without platform lock-in, vendor
fatigue, or maintenance burden. It is pragmatic, not ideological: when a
pragmatic choice reduces real friction or long-term cost, it beats purity.

This document describes the system as it actually behaves — including
where it deliberately bends its own rules. Where the code and this file
disagree, one of them is wrong; fix it.

### Axioms, with their honest boundaries

| Axiom | Working rule | Where it bends |
|---|---|---|
| 1. Pragmatic Longevity | POSIX sh, GNU Make, Git, Stow, plain text | A few scripts opt into bash for pipefail/arrays; the shebang is the source of truth |
| 2. Anti-Complexity | The whole build model fits in your head | One deliberate make idiom (`foreach` + `include`), used uniformly |
| 3. Structural Safety | Loud failures, strict permissions, backup before overwrite | Not offline: installs require the network and fail loudly without it |
| 4. Pragmatic Flow | Millisecond no-ops, standalone CLIs | A profile switch re-runs the installer once, for the new profile's set |

### Axiom 1 — Pragmatic Longevity

Foundations: POSIX sh, GNU Make, Git, plain text, GNU Stow
(`--no-folding`), standard UNIX utilities. Anything in this repository can
be inspected with `cat`, `find`, and `grep`.

bash is allowed where it earns its keep — realistically, `pipefail` and
arrays. Each use is visible in the shebang, and scripts do not gradually
accumulate bash-isms. On FreeBSD the make binary is `gmake`; everywhere
else `make`.

Avoided: configuration frameworks, dotfile DSLs, state daemons, formats
that require special tooling to read.

### Axiom 2 — Anti-Complexity

- **No external state database.** System state is the filesystem plus
  make's in-memory DAG.
- **Single-phase evaluation.** Targets evaluate on demand in one
  invocation. Nothing persists between runs except `.state/`, which is
  disposable at any moment (`make clean-state`).
- **Each dependency is declared exactly once.** A profile's module list
  drives both loading and build order; there is no second list to drift
  out of sync (§2.1).

### Axiom 3 — Structural Safety

- **Loud failures.** Package installs, binary fetches, and `vault sync`
  abort with visible errors and nonzero exits. Nothing reports success it
  did not earn: `vault sync` fails if the push fails.
- **Strict vault permissions.** `~/.vault` is clamped to `0700`
  (directories) and `0600`/`0700` (files) on every `apply` and `sync`, and
  on demand via `vault chmod`.
- **Backup before overwrite.** `dot` moves an unmanaged host file that
  would block a link into `~/.local/state/dot/backup/` instead of
  destroying it.
- **Network honesty.** Applying configuration is offline (stow, vault
  apply, prune, lint, fmt). Installing is online (apt/pkg/apk, fetch-bin)
  and fails loudly when the network is absent. This system is not
  offline-first; it is offline-safe for everything that does not fetch.

### Axiom 4 — Pragmatic Flow

- Shell startup performs zero work: no compilation, no network calls, no
  linking.
- An unchanged goal set with no module edits resolves in milliseconds.
- The core CLIs (`dot`, `vault`, `install-sys-pkg`, `fetch-bin`) run
  standalone from the terminal once `make base` has installed them; Make
  is orchestration, not a runtime dependency.

---

## 2. Architecture

```text
┌────────────────────────────────────────────┐
│ MAKE LAYER                                 │
│  goal-driven includes                      │
│  distro package-set accumulation           │
│  goal-keyed install stamps (§2.3)          │
│  DAG ordering, parallel-safe               │
└──────────────┬─────────────────────────────┘
               │ exports COMMON_PKGS DEBIAN_PKGS ... LIB_DIR
               ▼
┌────────────────────────────────────────────┐
│ SHELL LAYER (host-aware)                   │
│  install-sys-pkg · dot · vault · fetch-bin │
└────────────────────────────────────────────┘
```

### 2.1 Goal-driven includes, single-list profiles

`make <target>` includes `modules/<target>/<target>.mk` (the root Makefile
does this with `foreach` over `$(MAKECMDGOALS)`). Leaf modules pull their
dependencies with `include` lines guarded by `ifndef MOD_<NAME>`, so every
file parses at most once and `-j` stays safe.

Profiles — aggregators like `base`, `desktop` — declare their modules
once. That single list loads the modules and orders the build:

```makefile
BASE_MODULES := 7zip age bin env git jq lib rclone shell ssh stow vault recipes
$(foreach d,$(BASE_MODULES),$(eval include modules/$d/$d.mk))

.PHONY: base
base: sys-pkgs $(BASE_MODULES)
```

Because make expands prerequisites lazily, `$(BASE_MODULES)` at rule time
is exactly what was included. Nothing is listed twice.

### 2.2 Package accumulation

Modules append to distro-keyed sets; the root Makefile exports them to
subprocesses:

```makefile
COMMON_PKGS += ripgrep tmux
DEBIAN_PKGS += emacs-gtk elpa-magit
TERMUX_PKGS += emacs
```

### 2.3 The `sys-pkgs` barrier

Package installation is gated by one stamp file per goal set:

```makefile
empty :=
space := $(empty) $(empty)
GOALS := $(sort $(if $(MAKECMDGOALS),$(MAKECMDGOALS),help))
STAMP := $(STATE_DIR)/sys-pkgs-$(subst $(space),+,$(GOALS)).stamp

$(STAMP): $(MAKEFILE_LIST)
	@mkdir -p $(STATE_DIR)
	install-sys-pkg
	touch $@
```

Semantics, precisely:

- **Same goal set, no module edits** → the stamp is fresh →
  `install-sys-pkg` does not run; the build proceeds in milliseconds.
- **Any loaded module edited** → `$(MAKEFILE_LIST)` is newer than the
  stamp → reinstall.
- **Different goal set** (`make emacs` after `make desktop`) → a different
  stamp file → that goal's package set installs.

The goal keying exists because a single global stamp goes stale on profile
switches: `make desktop` followed by `make emacs` would see "recent stamp,
all modules older" and silently skip emacs's packages. The stamp file
names its own scope: `.state/sys-pkgs-emacs.stamp`,
`.state/sys-pkgs-desktop.stamp`, …

Known wrinkle, accepted: invoking unrelated goals together
(`make desktop lint`) keys a combined stamp and triggers one extra package
refresh. Run utility targets separately, or accept the refresh.

### 2.4 Shared recipe macro

Stowing a module is one line in every module makefile:

```makefile
stow-module = MODULES_DIR="$(MODULES_DIR)/$@" dot apply dotfiles
```

---

## 3. Package Delivery

### 3.1 `install-sys-pkg` (dual-mode installer)

- **Batch (from Make):** no arguments. Detects the distro via `os.sh`,
  unions `COMMON_PKGS` with the matching distro set, deduplicates, and
  installs with the system package manager.
- **Standalone:** `install-sys-pkg ripgrep tmux fzf` installs ad hoc from
  the terminal.

### 3.2 Library contract

Scripts resolve shared libraries (`os.sh`, `fetch.sh`) through exactly
two locations: `$LIB_DIR` (exported by Make) or `~/.local/lib` (installed,
standalone use). The pattern is three lines:

```sh
LIB="${LIB_DIR:-$HOME/.local/lib}/sh/fetch.sh"
[ -f "$LIB" ] || { echo "fetch.sh not found (run 'make base' first)" >&2; exit 1; }
. "$LIB"
```

`bootstrap` is the single sanctioned exception: it looks inside the
repository first, because it runs before anything is installed.

### 3.3 `fetch-bin` (binary fallback)

Installs prebuilt binaries to `~/.local/bin` from direct URLs or GitHub
releases (`gh:owner/repo` plus an asset regex), extracting common archive
formats.

Candidate selection, when no explicit binary name is given:

1. A file exactly matching the expected name.
2. Otherwise, the archive's single executable file.
3. Otherwise, the archive's single regular file.
4. Anything ambiguous fails loudly, listing every candidate.

Accepted trade, stated plainly: **no checksum or signature
verification.** fetch-bin trusts HTTPS and the source. Reasonable for a
personal system; do not copy this posture into anything multi-user.

---

## 4. Dotfile Management (`dot`)

`dot` wraps GNU Stow with conflict-safe preparation and a lock for
parallel make.

### 4.1 Rules

- **`--no-folding`, always.** Directories in `$HOME` stay real
  directories; only leaf files are symlinked.
- **Unmanaged host files** that would block a link are moved to
  `~/.local/state/dot/backup/` before Stow runs — never overwritten.
- **Stale or overridden symlinks** are removed so Stow relinks cleanly.
- **Shared directories** (`~/.config/autostart/`) accept files from
  multiple modules without collision.
- **Concurrency:** `flock` on `~/.local/state/dot.lock` serializes `dot`
  invocations under `make -j`.

### 4.2 Hygiene: `dot prune`

When a file is removed from a module, its link in `$HOME` goes stale.
`dot prune` removes broken links whose target resolves under
`MODULES_DIR`; broken links elsewhere in `$HOME` are never touched. Run it
after pulls that delete files:

```sh
dot prune
```

Known limit: if an entire module directory is deleted from the repository,
the links' parent chain no longer exists and prune cannot attribute them.
Remove such modules properly first (`dot remove <module>`) before deleting
them from the repository.

### 4.3 Usage

```sh
dot apply <module...>
dot remove <module...>
dot prune
dot ls
```

---

## 5. Sovereign Vault (`~/.vault`)

Private configuration, SSH keys, credentials, and machine-specific secrets
live in an unencrypted Git repository at `~/.vault/`, mirroring the module
layout of the system repository (`ssh/`, `git/`, `rclone/`, `base/`, …).

- **Permissions:** clamped to `0700` directories and `0600`/`0700` files
  on every `apply` and `sync`, and on demand via `vault chmod`.
- **Profiles** declare vault modules with `VAULT_MODULES += ssh base git
  rclone`; `make vault` applies them.

### 5.1 `vault sync` semantics

`sync` commits local changes, rebases on the upstream, and pushes. The
details that matter:

- The pull happens only once an upstream exists — the first `sync` after
  `vault init <url>` just pushes.
- **Push failures are not masked.** Network or auth failure exits nonzero
  with git's own error visible; `vault: synced` prints only after a real
  push.
- With no remote configured, `sync` says so explicitly and keeps the
  commit local.

### 5.2 Usage

```sh
vault init [remote-git-url]
vault sync
vault apply <module...>
vault remove <module...>
vault chmod
vault ls
vault git <command...>   # pass-through
```

---

## 6. Repository Layout

```text
.
├── bootstrap                 # Zero-to-Make minimal host primer
├── Makefile                   # DAG builder, stamps, package orchestrator
├── Dockerfile                 # Debian 13-slim container image
├── modules/
│   ├── base/                  # Core profile
│   ├── bin/                   # dot, vault, install-sys-pkg, fetch-bin, ...
│   ├── lib/                   # os.sh, fetch.sh (shared shell libraries)
│   ├── crontab/ desktop/ dev/ docker-base/ emacs/ env/
│   ├── phone/ pubnix/ recipes/ shell/ ssh/ stow/ vault/ wireproxy/
└── .state/                    # Ephemeral stamps (git-ignored, disposable)
```

Each module: `<name>.mk` (rules, packages, include guard), `dotfiles/`
(stowed files), optional `install` (binary fetcher).

---

## 7. Node Commissioning

### 7.1 Desktop (Debian 13+)

```sh
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system
./bootstrap desktop
vault init <VAULT_REPO_URL> && make vault
exec bash -l
```

### 7.2 Mobile (Android / Termux)

```sh
termux-setup-storage
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system
./bootstrap phone
vault init <VAULT_REPO_URL> && make vault
exec bash -l
```

### 7.3 Container (Docker base)

```sh
docker build -t system:base .
docker run -it --rm system:base
```

The image runs `./bootstrap docker-base` at build time and works as the
non-root user `esperoj`, who holds passwordless sudo for ad-hoc installs.
That is a container-only convenience for disposable environments. Desktop
nodes use ordinary sudo; NOPASSWD has no place on a persistent host.

### 7.4 Pubnix (shared rootless UNIX)

```sh
git clone <SYSTEM_REPO_URL> ~/projects/system
cd ~/projects/system
./bootstrap pubnix
vault init <VAULT_REPO_URL> && make vault
exec bash -l
```

---

## 8. Daily Operation

```sh
cd ~/projects/system
git pull --rebase
make desktop            # or phone / docker-base / pubnix
dot prune               # after pulls that removed files
make -n desktop         # inspect the execution graph
```

Isolated modules: `make emacs`, `make git`, `make dev`.

Ad-hoc packages outside Make: `install-sys-pkg ripgrep`.

Force a full package re-evaluation: `make clean-state && make <profile>`.
Note stamps are per goal set — switching profiles does not need
clean-state.

Vault: `vault sync` (honest exit codes), `vault git status`, `vault ls`,
`vault chmod`.

---

## 9. Code Quality Contract

`make lint` runs shellcheck at **default severity** plus `shfmt -d`. There
are no blanket suppressions. Exactly three classes of finding are
disabled, each inline at its use site with its reason:

1. **Dynamic library sources** (`# shellcheck source=/dev/null`):
   libraries resolve through `$LIB_DIR`/`~/.local/lib` at runtime and
   cannot be followed statically.
2. **`test -ef` in `dot`**: not POSIX-specified, but implemented by every
   shell this system runs under (dash, bash, busybox, mksh, BSD sh) — and
   exactly the semantics needed: same file after link resolution.
3. **Deliberate word-splitting** of `$PKGS` in `install-sys-pkg`: split
   on purpose, to deduplicate line-per-package.

The rule going forward: a new warning is fixed, or it joins this list with
a justification. Silence is never the default.

`make fmt` formats in place (shfmt). `make review` sends the latest commit
to an AI reviewer — it needs network access for the model API; it is a
convenience, not part of the build.

### Host support, honestly

| Host | Status |
|---|---|
| Debian 13 — desktop, containers | Maintained; daily driver |
| Termux — phone | Maintained; daily driver |
| Alpine, FreeBSD | Code paths exist in `bootstrap`/`install-sys-pkg`; untested. Treat as unverified until exercised. |
````

Four lines depend on things I haven't seen the final state of — flip them if needed:

- **§7.3** assumes the Dockerfile still ships the sudo user. If you did the root-stage restructure (no sudo in the image), replace the last paragraph with: "Packages are installed in the root build stage; the runtime user has no sudo."
- **§9 host table** — if you pruned the alpine/freebsd branches, delete that row.
- **§2.1/§2.4** assume `refactor-modules.sh` ran (single lists + `@$(stow-module)`). If it hasn't, the README currently describes the target shape — run the migration so the two match.
- The bash wording is shebang-based ("the shebang is the source of truth"), so it stays accurate regardless of whether you converted `daily`/`anki`.

Everything else is written against behavior we implemented and verified together: stamp semantics, `vault sync` failure modes, `dot prune` scope and limit, fetch-bin candidate rules, the library contract, and the three shellcheck exception classes.
