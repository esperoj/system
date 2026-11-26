# The Makefile layer itself: help stays current and the dry-run graph
# of the core profile resolves without touching the network.

load 'test_helper'

@test "help introduces the goals, including the suite" {
	run make -C "$REPO_ROOT" help
	[ "$status" -eq 0 ]
	case "$output" in
	*"Usage: make <target>"*) ;;
	*) return 1 ;;
	esac
	case "$output" in
	*"test"*) ;;
	*) return 1 ;;
	esac
}

@test "make -n base resolves the whole profile graph" {
	run make -C "$REPO_ROOT" -n base
	[ "$status" -eq 0 ]
	case "$output" in
	*"install-tool rclone"*) ;;
	*) return 1 ;;
	esac
}
