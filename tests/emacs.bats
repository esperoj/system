# The Emacs layer: the modular init must load in batch, without the
# network, without ELPA packages, and with every documented binding.
# The suite itself is ERT under tests/emacs/; bats is only the runner.

load 'test_helper'

@test "the modular Emacs config loads hermetically" {
	if ! command -v emacs >/dev/null 2>&1; then
		skip "emacs not installed"
	fi
	run emacs -Q --batch -l "$REPO_ROOT/tests/emacs/run-tests.el"
	[ "$status" -eq 0 ]
}
