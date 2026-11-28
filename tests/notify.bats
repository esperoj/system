# notify - one email through curl's SMTP, pinned behind a mocked curl:
# the message shape (CRLF, RFC 5322 header order, body last) and the
# transport flags are the contract; the network is never touched. The
# CRLF checks are not garnish - curl passes the upload through verbatim
# and only dot-stuffs CRLF-delimited lines, so a bare-LF body line that
# is exactly "." would end the DATA block one line early.

load 'test_helper'

setup() {
	sandbox
	mocks
	mock_curl
	export SMTP_URL="smtp://smtp.example:587"
	export SMTP_USER="tester"
	export SMTP_PASS="secret"
	export MAIL_FROM="you@disroot.org"
	export MAIL_TO="you+system@disroot.org"
}

# The mock records curl's argv and the uploaded message, then succeeds;
# $HOME is the disposable sandbox, so the captures die with it.
mock_curl() {
	cat >"$MOCKS/curl" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"$HOME/curl.args"
cat >"$HOME/curl.stdin"
exit 0
EOF
	chmod +x "$MOCKS/curl"
}

@test "notify: no arguments is a usage error" {
	run notify
	[ "$status" -eq 1 ]
	case "$output" in
	*"usage: notify"*) ;;
	*) return 1 ;;
	esac
}

@test "notify: unset transport settings fail loudly" {
	unset SMTP_URL SMTP_USER SMTP_PASS MAIL_FROM MAIL_TO
	run notify "body"
	[ "$status" -ne 0 ]
	case "$output" in
	*"SMTP_URL must be set"*) ;;
	*) return 1 ;;
	esac
}

@test "notify: sends one RFC 5322 message through curl SMTP" {
	run notify "one line body" "Subject: [system] test"
	[ "$status" -eq 0 ]
	_args=$(cat "$HOME/curl.args")
	case "$_args" in
	*"--url smtp://smtp.example:587"*) ;;
	*) return 1 ;;
	esac
	case "$_args" in
	*"--mail-from you@disroot.org"*) ;;
	*) return 1 ;;
	esac
	case "$_args" in
	*"--mail-rcpt you+system@disroot.org"*) ;;
	*) return 1 ;;
	esac
	case "$_args" in
	*"--user tester:secret"*) ;;
	*) return 1 ;;
	esac
	case "$_args" in
	*--ssl-reqd*) ;;
	*) return 1 ;;
	esac
	# capture the message byte-exact: $(cat ...) alone eats the final
	# newline, and the body-last check anchors on it
	_msg=$(cat "$HOME/curl.stdin"; printf x)
	_msg=${_msg%x}
	case "$_msg" in
	"From: you@disroot.org"$'\r\n'To:*) ;;
	*) return 1 ;;
	esac
	case "$_msg" in
	*"Subject: [system] test"$'\r\n'Date:*) ;;
	*) return 1 ;;
	esac
	case "$_msg" in
	*Message-ID:*@*) ;;
	*) return 1 ;;
	esac
	case "$_msg" in
	*"MIME-Version: 1.0"$'\r\n'"Content-Type: text/plain; charset=UTF-8"$'\r\n'"Content-Transfer-Encoding: 8bit"$'\r\n'$'\r\n'*) ;;
	*) return 1 ;;
	esac
	case "$_msg" in
	*$'\r\n'"one line body"$'\r\n') ;;
	*) return 1 ;;
	esac
}

@test "notify: a multi-line body gets CRLF on every line" {
	run notify "line one
line two" "Subject: [system] t"
	[ "$status" -eq 0 ]
	_msg=$(cat "$HOME/curl.stdin"; printf x)
	_msg=${_msg%x}
	case "$_msg" in
	*$'\r\n'"line one"$'\r\n'"line two"$'\r\n') ;;
	*) return 1 ;;
	esac
}

@test "notify: smtps:// keeps implicit TLS and still demands a secure channel" {
	export SMTP_URL="smtps://smtp.example:465"
	run notify "body" "Subject: [system] t"
	[ "$status" -eq 0 ]
	case "$(cat "$HOME/curl.args")" in
	*--ssl-reqd*) ;;
	*) return 1 ;;
	esac
}

@test "notify: a subjectless send warns but still sends" {
	run notify "body only"
	[ "$status" -eq 0 ]
	case "$output" in
	*"notify: no Subject"*) ;;
	*) return 1 ;;
	esac
	case "$(cat "$HOME/curl.stdin")" in
	*"To: you+system@disroot.org"$'\r\n'"Date:"*) ;;
	*) return 1 ;;
	esac
}

@test "notify: every caller header lands in the message" {
	run notify "b" "Subject: [system] t" "X-System-Node: pc"
	[ "$status" -eq 0 ]
	case "$(cat "$HOME/curl.stdin")" in
	*"X-System-Node: pc"$'\r\n'Date:*) ;;
	*) return 1 ;;
	esac
}
