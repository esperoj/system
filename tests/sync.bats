# sync — the daily repo check, against sandbox git repos whose
# upstreams are local directories (no remote is ever contacted). The
# watch group is the one under oath: it must never act on its own.

load 'test_helper'

setup() {
	sandbox
	git config --global user.email sync@test
	git config --global user.name "sync test"
}

# A local upstream whose checked-out branch accepts pushes
# (receive.denyCurrentBranch=updateInstead), so a push really lands.
upstream() {
	up=$(mktemp -d "${TMPDIR:-/tmp}/bats-upstream-XXXXXX")
	git init -q -b main "$up"
	git -C "$up" config receive.denyCurrentBranch updateInstead
	printf 'base\n' >"$up/file"
	git -C "$up" add file
	git -C "$up" commit -qm base
	printf '%s\n' "$up"
}

@test "sync: a home with no repos is a quiet success" {
	run sync
	[ "$status" -eq 0 ]
	case "$output" in
	*"not present"*) ;;
	*) return 1 ;;
	esac
}

@test "sync: auto repos commit and push without asking" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/notes"
	printf 'change\n' >>"$HOME/projects/notes/file"
	run sync
	[ "$status" -eq 0 ]
	[ -z "$(git -C "$HOME/projects/notes" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 2 ]
	case "$output" in
	*"projects/notes: committed"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: watch repos are reported, never auto-committed" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/pkit"
	printf 'wip\n' >>"$HOME/projects/pkit/file"
	run sync
	[ "$status" -eq 0 ]
	[ -n "$(git -C "$HOME/projects/pkit" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 1 ]
	case "$output" in
	*"projects/pkit"*"needs attention"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: a watch repo with only unpushed commits is attention" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/pkit"
	printf 'local\n' >"$HOME/projects/pkit/file"
	git -C "$HOME/projects/pkit" commit -qam local
	run sync
	[ "$status" -eq 0 ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 1 ]
	case "$output" in
	*"ahead 1"*"needs attention"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: the vault is synced through vault itself" {
	up=$(upstream)
	vault init "$up" >/dev/null
	printf 'secret\n' >"$HOME/.vault/key"
	chmod 644 "$HOME/.vault/key"
	run sync
	[ "$status" -eq 0 ]
	[ -z "$(git -C "$HOME/.vault" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 2 ]
	[ "$(stat -c '%a' "$HOME/.vault/key")" = "600" ]
	rm -rf "$up"
}

@test "sync: interactive 'c' commits and pushes the watched repo" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/pkit"
	printf 'wip\n' >>"$HOME/projects/pkit/file"
	out=$(printf 'c\n' | SYNC_INTERACTIVE=1 sync 2>&1)
	[ -z "$(git -C "$HOME/projects/pkit" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 2 ]
	case "$out" in
	*"projects/pkit: committed"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: interactive 's' leaves the watched repo untouched" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/pkit"
	printf 'wip\n' >>"$HOME/projects/pkit/file"
	out=$(printf 's\n' | SYNC_INTERACTIVE=1 sync 2>&1)
	[ -n "$(git -C "$HOME/projects/pkit" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 1 ]
	rm -rf "$up"
}

@test "sync: interactive 'q' stops asking, later repos are only reported" {
	up=$(upstream)
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/pkit"
	git clone -q "$up" "$HOME/projects/other"
	printf 'wip\n' >"$HOME/projects/pkit/file"
	printf 'wip\n' >"$HOME/projects/other/file"
	out=$(printf 'q\n' | SYNC_WATCH_REPOS="projects/pkit projects/other" SYNC_INTERACTIVE=1 sync 2>&1)
	[ -n "$(git -C "$HOME/projects/pkit" status --porcelain)" ]
	[ -n "$(git -C "$HOME/projects/other" status --porcelain)" ]
	[ "$(git -C "$up" log --oneline | wc -l)" -eq 1 ]
	case "$out" in
	*"projects/other"*"needs attention"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: repos without a remote keep their changes local" {
	mkdir -p "$HOME/projects/notes"
	git init -q -b main "$HOME/projects/notes"
	printf 'note\n' >"$HOME/projects/notes/file"
	run sync
	[ "$status" -eq 0 ]
	[ -z "$(git -C "$HOME/projects/notes" status --porcelain)" ]
	case "$output" in
	*"no remote; changes kept local"*) ;;
	*) return 1 ;;
	esac
}

@test "sync: a failed push in an auto repo is a loud failure" {
	# The upstream keeps git's default receive.denyCurrentBranch=refuse,
	# so the push really is rejected; sync must say so and exit nonzero.
	up=$(mktemp -d "${TMPDIR:-/tmp}/bats-upstream-XXXXXX")
	git init -q -b main "$up"
	printf 'base\n' >"$up/file"
	git -C "$up" add file
	git -C "$up" commit -qm base
	mkdir -p "$HOME/projects"
	git clone -q "$up" "$HOME/projects/notes"
	printf 'change\n' >>"$HOME/projects/notes/file"
	run sync
	[ "$status" -ne 0 ]
	case "$output" in
	*"projects/notes failed to sync"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$up"
}

@test "sync: a commissioned shell's environment never leaks in" {
	# The real-world failure behind this fix: .profile exports
	# VAULT_ROOT (base.env, set -a) on every node this system
	# commissions, so `bats tests` from a login shell pointed
	# sync at the real vault — its push failed and every sync
	# test failed on `[ "$status" -eq 0 ]`. Rebuild that hostile
	# environment, re-enter the sandbox, and pin that none of it
	# reaches the run: not the vault, not the notify target, not
	# the repo lists, not the projects dir, not interactivity.
	_up=$(mktemp -d "${TMPDIR:-/tmp}/bats-leak-XXXXXX")
	git init -q -b main "$_up"
	printf 'v\n' >"$_up/file"
	git -C "$_up" add file
	git -C "$_up" commit -qm base
	export VAULT_ROOT="$_up"
	export NTFY_URL="https://ntfy.example/leaked"
	export SYNC_AUTO_REPOS="leaked-auto"
	export SYNC_WATCH_REPOS="leaked-watch"
	export SYNC_PROJECTS_DIR="$_up"
	export SYNC_INTERACTIVE=1
	_old_home=$HOME
	sandbox
	rm -rf "$_old_home"
	git config --global user.email sync@test
	git config --global user.name "sync test"
	[ "${GIT_CONFIG_GLOBAL:-}" = "$HOME/.gitconfig" ]
	[ "${GIT_CONFIG_SYSTEM:-}" = "/dev/null" ]
	[ -z "${XDG_CONFIG_HOME:-}" ]
	run sync
	[ "$status" -eq 0 ]
	case "$output" in
	*leak* | *ntfy.example* | *"$_up"*) return 1 ;;
	esac
	case "$output" in
	*"vault: not present; skipped"*) ;;
	*) return 1 ;;
	esac
	rm -rf "$_up"
}
