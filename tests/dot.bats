# dot — the Stow wrapper, against a real stow in a sandbox HOME.

load 'test_helper'

setup() {
	sandbox
	MODS="$HOME/modules"
	TGT="$HOME/target"
	mkdir -p "$TGT" "$MODS"
}

# A module claiming .config/<file>.
mkmod() {
	mkdir -p "$MODS/$1/dotfiles/.config"
	printf 'managed\n' >"$MODS/$1/dotfiles/.config/$2"
}

@test "dot ls lists the modules of MODULES_DIR" {
	mkmod alpha a.conf
	mkmod beta b.conf
	run env MODULES_DIR="$MODS" dot ls
	[ "$status" -eq 0 ]
	[ "$output" = "alpha
beta" ]
}

@test "dot apply links leaves and never folds directories" {
	mkmod alpha a.conf
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	[ "$status" -eq 0 ]
	[ -L "$TGT/.config/a.conf" ]
	[ ! -L "$TGT/.config" ]
	[ "$(cat "$TGT/.config/a.conf")" = "managed" ]
}

@test "dot apply backs up an unmanaged host file beside itself" {
	mkdir -p "$TGT/.config"
	printf 'host\n' >"$TGT/.config/a.conf"
	mkmod alpha a.conf
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	[ "$status" -eq 0 ]
	[ "$(cat "$TGT/.config/.a.conf.bak")" = "host" ]
	[ "$(cat "$TGT/.config/a.conf")" = "managed" ]
}

@test "dot apply backs up a blocking host directory beside itself" {
	mkmod alpha a.conf
	mkdir -p "$TGT/.config/a.conf"
	printf 'host\n' >"$TGT/.config/a.conf/inner"
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	[ "$status" -eq 0 ]
	[ -L "$TGT/.config/a.conf" ]
	[ "$(cat "$TGT/.config/.a.conf.bak/inner")" = "host" ]
}

@test "dot apply replaces a stale directory backup instead of failing" {
	# An old non-empty .dir.bak is exactly the case mv -f cannot
	# handle; apply must still carry the host dir into the fresh bak.
	mkmod alpha a.conf
	mkdir -p "$TGT/.config/a.conf"
	printf 'host\n' >"$TGT/.config/a.conf/inner"
	mkdir -p "$TGT/.config/.a.conf.bak/old"
	printf 'stale\n' >"$TGT/.config/.a.conf.bak/old/deep"
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	[ "$status" -eq 0 ]
	[ -L "$TGT/.config/a.conf" ]
	[ "$(cat "$TGT/.config/.a.conf.bak/inner")" = "host" ]
	[ ! -e "$TGT/.config/.a.conf.bak/old" ]
}

@test "dot apply is idempotent: a second run neither relinks nor backs up" {
	mkmod alpha a.conf
	env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	[ "$status" -eq 0 ]
	[ "$(cat "$TGT/.config/a.conf")" = "managed" ]
	[ ! -e "$TGT/.config/.a.conf.bak" ]
}

@test "dot remove unlinks the module's files" {
	mkmod alpha a.conf
	env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	run env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot remove dotfiles
	[ "$status" -eq 0 ]
	[ ! -e "$TGT/.config/a.conf" ]
}

@test "dot prune removes stale links, never foreign ones" {
	mkmod alpha a.conf
	env MODULES_DIR="$MODS/alpha" TARGET="$TGT" dot apply dotfiles
	rm "$MODS/alpha/dotfiles/.config/a.conf"
	ln -s /nonexistent-foreign "$TGT/.config/foreign"
	run env MODULES_DIR="$MODS" TARGET="$TGT" dot prune
	[ "$status" -eq 0 ]
	[ ! -e "$TGT/.config/a.conf" ]
	[ -L "$TGT/.config/foreign" ]
}

@test "dot refuses unknown modules loudly" {
	run env MODULES_DIR="$MODS" TARGET="$TGT" dot apply nosuchmod
	[ "$status" -ne 0 ]
	case "$output" in
	*"no such module"*) ;;
	*) return 1 ;;
	esac
}

@test "dot without a verb fails with the usage" {
	run env MODULES_DIR="$MODS" TARGET="$TGT" dot
	[ "$status" -ne 0 ]
	case "$output" in
	*"usage"*) ;;
	*) return 1 ;;
	esac
}
