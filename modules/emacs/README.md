# Sovereign Emacs Module

A 100% offline-first, low-dependency Emacs environment for Emacs 29+ on Debian-based systems. Built on built-in tools (`project.el`, `eglot`, `treesit`, `icomplete`), XDG standards, dual APT/ELPA package handling, `ocaml-lsp-server`, and a local-first Git workflow via Magit.

---

## 1. System Setup & Dependencies

Install base tools, language servers, and compiler toolchains before running Emacs.

### A. Base System & Build Tools

```bash
sudo apt update
sudo apt install -y \
  build-essential \
  git \
  pandoc \
  ripgrep \
  fd-find \
  curl \
  emacs \
  elpa-magit \
  elpa-markdown-mode \
  elpa-tuareg

```

### B. OCaml Toolchain (`opam` + `ocaml-lsp-server`)

Neither `tuareg` nor `ocp-indent` are pulled automatically by `ocaml-lsp-server`. Install `elpa-tuareg` via system packages, and explicitly install `ocaml-lsp-server`, `ocp-indent`, and `ocamlformat` (for LSP-driven code formatting) via OPAM. Standalone Emacs `merlin` packages are obsolete and unnecessary.

```bash
sudo apt install -y opam
opam init --auto-setup -y
eval $(opam env)
opam install -y ocaml-lsp-server ocp-indent ocamlformat dune

```

### C. Python Environment

```bash
sudo apt install -y python3 python3-venv python3-pip python3-full
pip install --user pyright

```

### D. Bash & JSON Tooling

```bash
sudo apt install -y shellcheck jq nodejs npm
sudo npm install -g bash-language-server vscode-langservers-extracted

```

### E. Binary Verification

Run this check to confirm all required executables exist on `$PATH`:

```bash
for cmd in git gcc pandoc opam ocamllsp ocp-indent ocamlformat dune python3 pyright shellcheck bash-language-server vscode-json-language-server; do
  printf "%-30s %s\n" "$cmd:" "$(command -v $cmd || echo 'MISSING')"
done

```

---

## 2. Practical Magit Workflows

Operate on a single `main` branch across all machines without pull requests, feature branches, or web forges. Open Magit at any time with `C-x g`.

### Happy Path: Daily Linear Sync Cycle

1. **Start of Session:** Press `C-x g` -> `F p` (**Pull**) to integrate commits from other nodes before editing.
2. **Incremental Staging:** Move point to a file, diff hunk, or highlight lines (`C-SPC`) -> press `s` (**Stage**).
3. **Commit Snapshot:** Press `c c` (**Commit**) -> write message -> press `C-c C-c` to finalize.
4. **End of Session:** Press `P p` (**Push**) to sync local commits to your remote target or backup drive.

---

### Unhappy Paths & Edge Case Recovery

#### 1. Uncommitted Local Edits vs. Remote Updates

* **Issue:** You edited local files on Machine A without pulling, and Machine B pushed new commits.
* **Fix:** Stash local work (`z z`) -> Fetch & Rebase (`F u`) -> Pop stash (`z p`).

#### 2. Diverged Local Commits vs. Remote Commits

* **Issue:** You created local commits on Machine A, but Machine B pushed first. `P p` is rejected.
* **Fix:** Fetch & Rebase onto upstream (`F u`). Magit re-stacks your local commits linearly on top of incoming work. Push with `P p`.

#### 3. Merge Conflicts During Rebase

* **Issue:** A rebase stops due to overlapping changes in a file.
* **Fix:**
1. Press `RET` on the flagged file under **Unmerged paths** to open it (`smerge-mode` activates automatically).
2. Jump between conflicts using `C-c ^ n` (Next) and `C-c ^ p` (Previous).
3. Keep local changes (`C-c ^ m`), remote changes (`C-c ^ o`), or both (`C-c ^ a`).
4. Save buffer (`C-x C-s`), stage file in Magit (`s`), and continue rebase (`r r`).



#### 4. Interrupted Work Between Machines (WIP Flow)

* **Issue:** You must switch machines immediately with unfinished, non-working code.
* **Fix:**
* *Machine A:* Stage all (`S`) -> Commit temporary state (`c c`, message: `wip`) -> Push (`P p`).
* *Machine B:* Pull (`F p`) -> complete task -> stage fixes (`s`) -> Amend commit (`c a`) -> overwrite `wip` message -> finalize (`C-c C-c`).



#### 5. Local Commit Curation

* **Amend Head Commit:** Stage new changes -> press `c a` (Amend) or `c e` (Extend without changing message).
* **Absorb Fix into Past Commit:** Stage changes -> press `c f` (**Fixup**) -> select target commit.
* **Reorder / Combine / Delete Local Commits:** Press `r i` (**Interactive Rebase**) -> move point -> use `r` (reword), `s` (squash), `d` (drop), or `M-p`/`M-n` (move up/down) -> press `C-c C-c`.

#### 6. Errors & Disaster Recovery

* **Discard Local Edits:** Position point over file/hunk in *Unstaged changes* -> press `k` (**Discard**) -> confirm.
* **Undo Commit (Keep Edits):** Press `X m` (**Soft Reset**) -> select `HEAD~1`.
* **Destroy Bad Commit & Edits:** Press `X h` (**Hard Reset**) -> select `HEAD~1`.
* **Recover Lost/Deleted Commits:** Press `l r` (**Reflog**) -> select missing commit -> press `A` (Cherry-pick) or `X h` (Reset).

---

### Magit Command Quick Reference

| Action | Keybinding | Purpose |
| --- | --- | --- |
| **Status View** | `C-x g` | Open repository dashboard |
| **Stage / Unstage** | `s` / `u` | Stage/unstage file, hunk, or region |
| **Stage All / Unstage All** | `S` / `U` | Stage or unstage working tree |
| **Discard Changes** | `k` | Erase uncommitted edits at point |
| **Commit / Amend** | `c c` / `c a` | Write new commit / update head commit |
| **Absorb Fixup** | `c f` | Merge staged edits into an older commit |
| **Stash / Pop Stash** | `z z` / `z p` | Hold / restore temporary uncommitted edits |
| **Pull & Rebase** | `F u` | Fetch remote commits and rebase local commits on top |
| **Continue Rebase** | `r r` | Resume rebase after resolving conflict |
| **Interactive Rebase** | `r i` | Reorder, squash, or reword past commits |
| **Reflog Recovery** | `l r` | Inspect audit trail to restore lost state |

---

## 3. Language & Tooling Workflows

### OCaml (`tuareg-mode` + `ocamllsp`)

* **LSP Engine:** `eglot` auto-starts `ocamllsp` for `.ml`/`.mli` files.
* **Indentation & Formatting:** Uses `ocp-indent` for standalone buffer indentation and `ocamlformat` via Eglot for full buffer formatting (`M-x eglot-format-buffer`).
* **Navigation:** `M-.` (Go to definition), `M-,` (Pop back), `M-?` (Find references).

### Python (`python-base-mode` + `pyright`)

* **Venv Auto-Activation:** Scans project root for `.venv` or `venv`, updates Emacs `exec-path` and system `PATH`, and binds environment binaries dynamically.
* **LSP Engine:** Connects `pyright` via `eglot`.

### Bash & JSON

* **Bash (`bash-ts-mode` / `sh-mode`):** Connects `bash-language-server` via `eglot`; presents `shellcheck` diagnostics inline.
* **JSON (`json-ts-mode` / `js-json-mode`):** Connects `vscode-json-language-server` via `eglot`; enforces 2-space indentation.

### Markdown (`gfm-mode`)

* **Header Folding:** Press `TAB` on headings (`#`, `##`) to toggle section visibility; press `S-TAB` to fold/unfold all headings.
* **Table Alignment:** Type pipe structures (`| col 1 | col 2 |`) and press `TAB` anywhere inside to format table grids.
* **Offline Preview:** Press `C-c C-c p` to render HTML locally via `pandoc` and view in a browser.

---

## 4. Navigation & Project Management

### Projects (`project.el`)

Project roots are automatically detected via `.git` directories.

* `C-c p p` : Switch active project.
* `C-c p f` : Find file within active project.
* `M-x project-find-regexp` : Search project files using `ripgrep`.

### Minibuffer Completion (`icomplete-vertical-mode`)

Substring and flex matching across all buffers and files.

* `C-n` / `C-p` : Move down / up in minibuffer completion list.
* `RET` : Select highlighted completion.
* `C-c r` : Open fuzzy list of recent files (`recentf-open-files`).

### Window Layouts (`winner-mode`)

* `M-o` : Focus next window (`other-window`).
* `C-c <left>` : Undo last window layout split or closure.
* `C-c <right>` : Redo window layout split or closure.
