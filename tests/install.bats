# The installer gates: install-sys-pkg's privilege model and
# install-tool's PATH rule, tested on the paths that stay offline.

load 'test_helper'

@test "install-sys-pkg: pubnix machines skip loudly and exit 0" {
	sandbox
	run env MACHINE_TYPE=pubnix COMMON_PKGS="alpha beta" LIB_DIR="$LIB_DIR" install-sys-pkg
	[ "$status" -eq 0 ]
	case "$output" in
	*"MACHINE_TYPE=pubnix"*) ;;
	*) return 1 ;;
	esac
	case "$output" in
	*"alpha beta"*) ;;
	*) return 1 ;;
	esac
}

@test "install-sys-pkg: an empty package set is a silent no-op" {
	sandbox
	run env COMMON_PKGS="" DEBIAN_PKGS="" TERMUX_PKGS="" ALPINE_PKGS="" FREEBSD_PKGS="" \
	        LIB_DIR="$LIB_DIR" install-sys-pkg
	[ "$status" -eq 0 ]
	[ -z "$output" ]
}

@test "install-sys-pkg: no library is a loud failure" {
	sandbox
	run env LIB_DIR=/nonexistent install-sys-pkg somepkg
	[ "$status" -ne 0 ]
	case "$output" in
	*"lib.sh not found"*) ;;
	*) return 1 ;;
	esac
}

@test "install-sys-pkg: a missing library is a loud failure, wherever it is sought" {
	sandbox
	run env -u LIB_DIR HOME=/nonexistent-home install-sys-pkg somepkg
	[ "$status" -ne 0 ]
	case "$output" in
	*"lib.sh not found"*) ;;
	*) return 1 ;;
	esac
}

@test "install-tool: usage without arguments" {
	run install-tool
	[ "$status" -ne 0 ]
	case "$output" in
	*"usage"*) ;;
	*) return 1 ;;
	esac
}

@test "install-tool: a tool already on PATH is never fetched" {
	sandbox
	mocks
	printf '#!/bin/sh\nexit 0\n' >"$MOCKS/jq"
	chmod +x "$MOCKS/jq"
	run env LIB_DIR="$LIB_DIR" install-tool jq gh:jqlang/jq 'jq-{OS}-{ARCH}$'
	[ "$status" -eq 0 ]
	case "$output" in
	*"already installed"*) ;;
	*) return 1 ;;
	esac
}

@test "install-tool: --update on a host-provided copy reports, never fetches" {
	sandbox
	mocks
	printf '#!/bin/sh\nexit 0\n' >"$MOCKS/jq"
	chmod +x "$MOCKS/jq"
	run env LIB_DIR="$LIB_DIR" install-tool --update jq gh:jqlang/jq 'jq-{OS}-{ARCH}$'
	[ "$status" -eq 0 ]
	case "$output" in
	*"provided by the host"*) ;;
	*) return 1 ;;
	esac
}

@test "install-tool: no library is a loud failure" {
	sandbox
	run env LIB_DIR=/nonexistent install-tool jq gh:jqlang/jq
	[ "$status" -ne 0 ]
	case "$output" in
	*"lib.sh not found"*) ;;
	*) return 1 ;;
	esac
}

@test "uninstall-tool: usage without arguments" {
	run uninstall-tool
	[ "$status" -ne 0 ]
}

@test "uninstall-tool: removes a fetched tool and its release record" {
	sandbox
	mkdir -p "$HOME/.local/bin" "$HOME/.local/state/system/tools/foo"
	printf '#!/bin/sh\n' >"$HOME/.local/bin/foo"
	printf 'recorded\n' >"$HOME/.local/state/system/tools/foo/url"
	run uninstall-tool foo
	[ "$status" -eq 0 ]
	[ ! -e "$HOME/.local/bin/foo" ]
	[ ! -e "$HOME/.local/state/system/tools/foo" ]
}

@test "uninstall-tool: host-provided copies are reported, never removed" {
	sandbox
	mocks
	printf '#!/bin/sh\nexit 0\n' >"$MOCKS/foo"
	chmod +x "$MOCKS/foo"
	run env PATH="$PATH" uninstall-tool foo
	[ "$status" -eq 0 ]
	case "$output" in
	*"provided by the host"*) ;;
	*) return 1 ;;
	esac
	[ -e "$MOCKS/foo" ]
}

@test "uninstall-tool: an unknown tool is a quiet success" {
	run uninstall-tool nosuchtool
	[ "$status" -eq 0 ]
	case "$output" in
	*"not installed"*) ;;
	*) return 1 ;;
	esac
}

@test "fetch-bin: usage without arguments" {
	run fetch-bin
	[ "$status" -ne 0 ]
	case "$output" in
	*"Usage"*) ;;
	*) return 1 ;;
	esac
}

@test "fetch-bin: no library is a loud failure" {
	sandbox
	run env LIB_DIR=/nonexistent fetch-bin "https://example.com/x"
	[ "$status" -ne 0 ]
	case "$output" in
	*"lib.sh not found"*) ;;
	*) return 1 ;;
	esac
}
