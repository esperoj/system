# Shared test environment, loaded by every suite (bats load directive).
# The suites stay hermetic: the repo's CLIs come first on PATH, scripts
# see a disposable HOME under a recognised prefix (torn down per test),
# and binaries the suite must not fetch are answered by mock scripts.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)"
export REPO_ROOT
export LIB_DIR="$REPO_ROOT/modules/lib/dotfiles/.local/lib"
export PATH="$REPO_ROOT/modules/bin/dotfiles/.local/bin:$PATH"

# A disposable HOME for one test; the XDG dirs follow it, so no real
# state (~/.local/state/system, real completions) is ever touched.
sandbox() {
	HOME="$(mktemp -d "${TMPDIR:-/tmp}/bats-sandbox-XXXXXX")"
	export HOME
	export XDG_STATE_HOME="$HOME/.local/state"
	export XDG_DATA_HOME="$HOME/.local/share"
	unset MACHINE_TYPE
	mkdir -p "$XDG_STATE_HOME" "$XDG_DATA_HOME"
}

# A directory of mock executables, first on PATH for this test.
mocks() {
	MOCKS="$(mktemp -d "${TMPDIR:-/tmp}/bats-mocks-XXXXXX")"
	export MOCKS
	export PATH="$MOCKS:$PATH"
}

# mock_uname <sys> <machine>: answer `uname -s` / `uname -m` with fixed
# values. A file on PATH, not a shell function, so every shell the
# system uses (dash included) sees the same answers.
mock_uname() {
	: "${MOCKS:?call mocks first}"
	_ums="${1:-Linux}"
	_umm="${2:-x86_64}"
	cat >"$MOCKS/uname" <<EOF
#!/bin/sh
# test mock: fixed answers for uname -s / -m
case "\${1:-}" in
-s) printf '%s\n' '$_ums' ;;
-m) printf '%s\n' '$_umm' ;;
*) command -p uname "\$@" ;;
esac
EOF
	chmod +x "$MOCKS/uname"
	unset _ums _umm
}

# The marker command lib.sh's android detection looks for.
mock_termux() {
	: "${MOCKS:?call mocks first}"
	printf '#!/bin/sh\nexit 0\n' >"$MOCKS/termux-info"
	chmod +x "$MOCKS/termux-info"
}

teardown() {
	case "${HOME:-}" in
	*/bats-sandbox-*) rm -rf "$HOME" ;;
	esac
	case "${MOCKS:-}" in
	*/bats-mocks-*) rm -rf "$MOCKS" ;;
	esac
}
