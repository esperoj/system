# lib.sh — the engines: OS/arch/machine resolution and the offline parts
# of the fetch engine. The environment the library reads is fully mocked
# (uname through a PATH file, env files through the sandbox HOME), so
# these tests hold on every host that can run bats.

load 'test_helper'

LIB="$REPO_ROOT/modules/lib/dotfiles/.local/lib/sh/lib.sh"

@test "OS engine: linux x86_64 maps to the three arch naming styles" {
	mocks
	mock_uname Linux x86_64
	run sh -c '. "$1"; printf "%s %s %s %s\n" "$OS" "$ARCH" "$XARCH" "$UARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "linux amd64 x64 x86_64" ]
}

@test "OS engine: aarch64 is Go arm64, vendor arm64, uname aarch64" {
	mocks
	mock_uname Linux aarch64
	run sh -c '. "$1"; printf "%s %s %s %s\n" "$OS" "$ARCH" "$XARCH" "$UARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "linux arm64 arm64 aarch64" ]
}

@test "OS engine: armv7l is Go armhf, vendor arm, uname armv7l" {
	mocks
	mock_uname Linux armv7l
	run sh -c '. "$1"; printf "%s %s %s %s\n" "$OS" "$ARCH" "$XARCH" "$UARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "linux armhf arm armv7l" ]
}

@test "OS engine: FreeBSD is its own OS and distro" {
	mocks
	mock_uname FreeBSD x86_64
	run sh -c '. "$1"; printf "%s %s %s %s\n" "$OS" "$DISTRO" "$ARCH" "$UARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "freebsd freebsd amd64 x86_64" ]
}

@test "OS engine: an unknown kernel is honest about it, arch untouched" {
	mocks
	mock_uname SunOS x86_64
	run sh -c '. "$1"; printf "%s %s %s\n" "$OS" "$DISTRO" "$UARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "unknown unknown x86_64" ]
}

@test "OS engine: the termux marker makes Linux read as android/termux" {
	mocks
	mock_uname Linux aarch64
	mock_termux
	run sh -c '. "$1"; printf "%s %s %s\n" "$OS" "$DISTRO" "$ARCH"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "android termux arm64" ]
}

@test "machine engine: an explicit MACHINE_TYPE wins over env files" {
	sandbox
	mkdir -p "$HOME/.config/env"
	printf 'MACHINE_TYPE=from-file\n' >"$HOME/.config/env/machine.env"
	run env MACHINE_TYPE=explicit sh -c '. "$1"; printf "%s\n" "$MACHINE_TYPE"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "explicit" ]
}

@test "machine engine: env files supply the identity otherwise" {
	sandbox
	mkdir -p "$HOME/.config/env"
	printf 'MACHINE_TYPE=from-file\n' >"$HOME/.config/env/machine.env"
	run sh -c '. "$1"; printf "%s\n" "$MACHINE_TYPE"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "from-file" ]
}

@test "machine engine: nothing supplies it, and it says so (empty)" {
	sandbox
	run sh -c '. "$1"; printf "%s\n" "${MACHINE_TYPE:-unset}"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "unset" ]
}

@test "fetch engine: direct https URLs pass through untouched" {
	run sh -c '. "$1"; fetch_resolve_url "https://example.com/some/asset.tar.gz"' sh "$LIB"
	[ "$status" -eq 0 ]
	[ "$output" = "https://example.com/some/asset.tar.gz" ]
}

@test "fetch engine: unsupported schemes fail loudly" {
	run sh -c '. "$1"; fetch_resolve_url "ftp://nope.invalid/x"' sh "$LIB"
	[ "$status" -ne 0 ]
	case "$output" in
	*"Unsupported source scheme"*) ;;
	*) return 1 ;;
	esac
}

@test "fetch engine: extraction unpacks a tarball" {
	sandbox
	mkdir -p "$HOME/src/pkg"
	printf 'payload\n' >"$HOME/src/pkg/file.txt"
	tar -czf "$HOME/src/pkg.tar.gz" -C "$HOME/src" pkg
	mkdir -p "$HOME/out"
	run sh -c '. "$1"; fetch_extract "$2" "$3"' sh "$LIB" "$HOME/src/pkg.tar.gz" "$HOME/out"
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/out/pkg/file.txt")" = "payload" ]
}

@test "fetch engine: extraction unpacks a single gzipped file" {
	sandbox
	printf 'payload2\n' >"$HOME/plain"
	gzip "$HOME/plain"
	mkdir -p "$HOME/out"
	run sh -c '. "$1"; fetch_extract "$2" "$3"' sh "$LIB" "$HOME/plain.gz" "$HOME/out"
	[ "$status" -eq 0 ]
	[ "$(cat "$HOME/out/plain")" = "payload2" ]
}
