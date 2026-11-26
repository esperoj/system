# shell — the interactive-layer module: .profile's completion loading
# (the "source it on launch or not" answer ISSUES.org asked for, pinned)
# and the make-target completion the module ships alongside it.

load 'test_helper'

PROFILE="$REPO_ROOT/modules/shell/dotfiles/.profile"
MAKE_COMP="$REPO_ROOT/modules/shell/dotfiles/.local/share/bash-completion/completions/make"

@test ".profile sources every user completion for interactive bash" {
	sandbox
	mkdir -p "$XDG_DATA_HOME/bash-completion/completions"
	printf '_usercomp_was_sourced() { :; }\n' >"$XDG_DATA_HOME/bash-completion/completions/probe"
	run env HOME="$HOME" XDG_DATA_HOME="$XDG_DATA_HOME" \
		bash --noprofile --norc -c ". '$PROFILE'; type _usercomp_was_sourced"
	[ "$status" -eq 0 ]
}

@test ".profile needs no completions directory to exist" {
	sandbox
	run env HOME="$HOME" XDG_DATA_HOME="$XDG_DATA_HOME" \
		bash --noprofile --norc -c ". '$PROFILE'; printf ok"
	[ "$status" -eq 0 ]
	[ "$output" = "ok" ]
}

@test "the make completion registers for make and m" {
	run bash --noprofile --norc -c ". '$MAKE_COMP'; complete -p make m"
	[ "$status" -eq 0 ]
}

@test "the make completion sees this repo's module goals" {
	run bash --noprofile --norc -c "cd '$REPO_ROOT'; . '$MAKE_COMP'; _system_make_targets"
	[ "$status" -eq 0 ]
	case "$output" in
	*"rclone-update"*) ;;
	*) return 1 ;;
	esac
}
