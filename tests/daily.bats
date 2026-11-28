# daily - the cron wrapper: sync first, backup second, and since the
# email transport one [system] daily failed email when either phase
# fails, so a dead routine is never mistaken for a quiet one. The sync,
# make and notify phases are mocks on PATH here; the real daily is the
# script under oath - it must send exactly one email on failure and
# none on a clean day, and never let a failed notify mask the verdict.

load 'test_helper'

setup() {
	sandbox
	mocks
	# daily sources ~/.profile; an empty one is the minimal contract
	: >"$HOME/.profile"
	mock_notify
}

# The mock records the one email daily is allowed to send.
mock_notify() {
	cat >"$MOCKS/notify" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$HOME/notify.args"
exit 0
EOF
	chmod +x "$MOCKS/notify"
}

# A phase mock that always exits with the given status.
phase() {
	printf '#!/bin/sh\nexit %s\n' "$2" >"$MOCKS/$1"
	chmod +x "$MOCKS/$1"
}

@test "daily: a clean day sends no email" {
	phase sync 0
	phase make 0
	run daily
	[ "$status" -eq 0 ]
	[ ! -f "$HOME/notify.args" ]
}

@test "daily: a failed sync sends one [system] daily failed email" {
	phase sync 1
	phase make 0
	run daily
	[ "$status" -eq 1 ]
	[ -f "$HOME/notify.args" ]
	case "$(cat "$HOME/notify.args")" in
	*"Subject: [system] daily failed on"*) ;;
	*) return 1 ;;
	esac
	case "$(cat "$HOME/notify.args")" in
	*"sync failed"*) ;;
	*) return 1 ;;
	esac
	case "$(cat "$HOME/notify.args")" in
	*log/daily-cron*) ;;
	*) return 1 ;;
	esac
}

@test "daily: a failed backup sends the email too" {
	phase sync 0
	phase make 1
	run daily
	[ "$status" -eq 1 ]
	[ -f "$HOME/notify.args" ]
	case "$(cat "$HOME/notify.args")" in
	*"backup failed"*) ;;
	*) return 1 ;;
	esac
}

@test "daily: a failed notify is loud but never masks the verdict" {
	phase sync 1
	phase make 1
	printf '#!/bin/sh\necho "notify: boom" >&2\nexit 1\n' >"$MOCKS/notify"
	chmod +x "$MOCKS/notify"
	run daily
	[ "$status" -eq 1 ]
	case "$output" in
	*"daily: notify failed"*) ;;
	*) return 1 ;;
	esac
}
