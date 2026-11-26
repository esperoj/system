# vault — the sovereign-secrets manager, against a sandbox HOME (git
# is the only external tool these need; no remote is ever contacted).

load 'test_helper'

setup() {
	sandbox
	export VAULT_ROOT="$HOME/.vault"
}

@test "vault init on an empty home creates a git vault, clamped to 0700" {
	run vault init
	[ "$status" -eq 0 ]
	[ -d "$VAULT_ROOT/.git" ]
	[ "$(stat -c '%a' "$VAULT_ROOT")" = "700" ]
	case "$output" in
	*"ready"*) ;;
	*) return 1 ;;
	esac
}

@test "vault init is idempotent" {
	vault init >/dev/null
	run vault init
	[ "$status" -eq 0 ]
}

@test "vault ls lists the vault's modules" {
	vault init >/dev/null
	mkdir -p "$VAULT_ROOT/ssh"
	run vault ls
	[ "$status" -eq 0 ]
	[ "$output" = "ssh" ]
}

@test "vault apply refuses unknown modules loudly" {
	vault init >/dev/null
	run vault apply nope
	[ "$status" -ne 0 ]
	case "$output" in
	*"no vault module"*) ;;
	*) return 1 ;;
	esac
}

@test "vault apply stows a vault module into HOME" {
	vault init >/dev/null
	mkdir -p "$VAULT_ROOT/git/.config"
	printf 'vaultfile\n' >"$VAULT_ROOT/git/.config/gitfile"
	run vault apply git
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/.config/gitfile")" = "vaultfile" ]
}

@test "vault chmod clamps file permissions" {
	vault init >/dev/null
	mkdir -p "$VAULT_ROOT/sub"
	printf 'secret\n' >"$VAULT_ROOT/sub/key"
	chmod 644 "$VAULT_ROOT/sub/key"
	run vault chmod
	[ "$status" -eq 0 ]
	[ "$(stat -c '%a' "$VAULT_ROOT/sub/key")" = "600" ]
}

@test "vault refuses commands without a vault, loudly" {
	run vault sync
	[ "$status" -ne 0 ]
	case "$output" in
	*"no vault"*) ;;
	*) return 1 ;;
	esac
}

@test "vault init pre-creates the root 700, a failing clone and all" {
	# A clone that fails never ran lock_perms; the root must still be
	# exactly what init created — 700, never the umask's 755.
	umask 022
	run vault init /nonexistent-upstream-repo
	[ "$status" -ne 0 ]
	[ -d "$VAULT_ROOT" ]
	[ "$(stat -c '%a' "$VAULT_ROOT")" = "700" ]
}

@test "vault init adopts a local clone and clamps its secrets" {
	umask 022
	git config --global user.email vault@test
	git config --global user.name "vault test"
	upstream=$(mktemp -d "${TMPDIR:-/tmp}/bats-upstream-XXXXXX")
	git init -q -b main "$upstream"
	printf 'secret
' >"$upstream/key"
	git -C "$upstream" add key
	git -C "$upstream" commit -qm base
	run vault init "$upstream"
	[ "$status" -eq 0 ]
	[ "$(cat "$VAULT_ROOT/key")" = "secret" ]
	[ "$(stat -c '%a' "$VAULT_ROOT")" = "700" ]
	[ "$(stat -c '%a' "$VAULT_ROOT/key")" = "600" ]
	rm -rf "$upstream"
}

@test "vault sync clamps permissions even when the rebase conflicts" {
	git config --global user.email vault@test
	git config --global user.name "vault test"
	upstream=$(mktemp -d "${TMPDIR:-/tmp}/bats-upstream-XXXXXX")
	git init -q -b main "$upstream"
	printf 'base
' >"$upstream/key"
	git -C "$upstream" add key
	git -C "$upstream" commit -qm base
	vault init "$upstream" >/dev/null
	# Diverge the same file on both ends, and loosen the vault copy: a
	# sync from here must fail on the rebase yet still clamp to 600.
	printf 'upstream
' >"$upstream/key"
	git -C "$upstream" commit -qam upstream
	printf 'local
' >"$VAULT_ROOT/key"
	chmod 644 "$VAULT_ROOT/key"
	run vault sync
	[ "$status" -ne 0 ]
	[ "$(stat -c '%a' "$VAULT_ROOT/key")" = "600" ]
	rm -rf "$upstream"
}
