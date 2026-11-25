#!/bin/sh
# lib.sh - the system's single shared shell library.
# Resolved through the two-location contract: $LIB_DIR (set by Make or
# bootstrap, pointing at the repo) or ~/.local/lib (installed, standalone).
# Sections: OS engine (exports OS DISTRO ARCH XARCH), machine engine
# (resolves MACHINE_TYPE: explicit environment first, then
# ~/.config/env/*.env) and fetch engine (URL resolution, download,
# extraction — used by fetch-bin).
set -eu

# --- OS engine ---------------------------------------------------------
_uname_s=$(uname -s)
_uname_m=$(uname -m)

case "$_uname_s" in
Linux)
	if [ -d /data/data/com.termux ] || command -v termux-info >/dev/null 2>&1; then
		OS="android"
		DISTRO="termux"
	elif [ -f /etc/alpine-release ]; then
		OS="linux"
		DISTRO="alpine"
	elif [ -f /etc/debian_version ]; then
		OS="linux"
		DISTRO="debian"
	else
		OS="linux"
		DISTRO="unknown"
	fi
	;;
FreeBSD)
	OS="freebsd"
	DISTRO="freebsd"
	;;
*)
	OS="unknown"
	DISTRO="unknown"
	;;
esac

# ARCH: Go/Debian-style names. XARCH: the vendor style some release
# archives use instead (7zip names amd64 "x64").
case "$_uname_m" in
x86_64) ARCH="amd64" XARCH="x64" ;;
aarch64 | arm64) ARCH="arm64" XARCH="arm64" ;;
armv7l) ARCH="armhf" XARCH="arm" ;;
i386 | i686) ARCH="386" XARCH="386" ;;
*) ARCH="$_uname_m" XARCH="$_uname_m" ;;
esac

export OS DISTRO ARCH XARCH
unset _uname_s _uname_m

# --- Machine engine ----------------------------------------------------
# MACHINE_TYPE names the node's role (pubnix, desktop, phone, docker-base).
# Precedence, stated once:
#   1. an explicit environment value always wins (make goals export it,
#      CI and `docker run -e` set it, an ad-hoc shell can override it);
#   2. otherwise the installed env files (~/.config/env/*.env — the same
#      files .profile exports at login) supply it, so non-login contexts
#      (make recipes, cron, one-shot ssh) see the identity too;
#   3. otherwise it exports empty and the node stays unnamed.
# Files are sourced but not re-exported: only MACHINE_TYPE leaves this
# section, so no other login-time variable leaks into installers.
if [ -z "${MACHINE_TYPE:-}" ] && [ -d "$HOME/.config/env" ]; then
	for _env in "$HOME"/.config/env/*.env; do
		[ -f "$_env" ] || continue
		# shellcheck source=/dev/null
		. "$_env"
	done
fi
export MACHINE_TYPE="${MACHINE_TYPE:-}"
unset _env

# --- Fetch engine ------------------------------------------------------

# Resolve input to a concrete download URL
# Supports:
#   - Direct HTTP/HTTPS URLs (passthrough)
#   - GitHub repos via "gh:owner/repo" [regex] (API with sed/jq + expanded_assets web fallback)
fetch_resolve_url() {
	_source="$1"
	_pattern="${2:-}"
	case "$_source" in
	http://* | https://*)
		echo "$_source"
		;;
	gh:*)
		_repo="${_source#gh:}"
		if [ -n "$_pattern" ]; then
			_url=""

			# 1. Attempt GitHub REST API (authenticated or unauthenticated)
			_api_url="https://api.github.com/repos/${_repo}/releases/latest"
			_auth_header=""
			[ -n "${GITHUB_TOKEN:-}" ] && _auth_header="Authorization: Bearer ${GITHUB_TOKEN}"

			if [ -n "$_auth_header" ]; then
				_json=$(curl -fsSL -H "User-Agent: fetch-bin" -H "Accept: application/vnd.github+json" -H "$_auth_header" "$_api_url" 2>/dev/null) || _json=""
			else
				_json=$(curl -fsSL -H "User-Agent: fetch-bin" -H "Accept: application/vnd.github+json" "$_api_url" 2>/dev/null) || _json=""
			fi

			if [ -n "$_json" ]; then
				# If jq is available, use it; otherwise parse with POSIX sed (breaks chicken-and-egg dependency)
				if command -v jq >/dev/null 2>&1; then
					_url=$(printf '%s\n' "$_json" | jq -r '.assets[].browser_download_url // empty' 2>/dev/null | grep -E "$_pattern" | head -n 1 || true)
				fi
				if [ -z "$_url" ]; then
					_url=$(printf '%s\n' "$_json" | sed -n 's/.*"browser_download_url":[[:space:]]*"\([^"]*\)".*/\1/p' | grep -E "$_pattern" | head -n 1 || true)
				fi
			fi

			# 2. Fallback: Scrape GitHub's expanded_assets fragment (bypasses API rate limits)
			if [ -z "$_url" ]; then
				_html_rel=$(curl -fsSL "https://github.com/${_repo}/releases/latest" 2>/dev/null) || _html_rel=""
				_assets_path=$(printf '%s\n' "$_html_rel" | grep -oE '[^"]*expanded_assets/[^"]+' | head -n 1 || true)

				_assets_url=""
				if [ -n "$_assets_path" ]; then
					case "$_assets_path" in
					http://* | https://*) _assets_url="$_assets_path" ;;
					/*) _assets_url="https://github.com${_assets_path}" ;;
					*) _assets_url="https://github.com/${_assets_path}" ;;
					esac
				else
					# Derive tag from redirect if the fragment tag was not in the HTML
					_tag=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${_repo}/releases/latest" 2>/dev/null | sed -e 's|.*/releases/tag/||' -e 's|.*/tag/||')
					if [ -n "$_tag" ] && [ "$_tag" != "https://github.com/${_repo}/releases/latest" ]; then
						_assets_url="https://github.com/${_repo}/releases/expanded_assets/${_tag}"
					fi
				fi

				if [ -n "$_assets_url" ]; then
					_html_assets=$(curl -fsSL "$_assets_url" 2>/dev/null) || _html_assets=""
					_url=$(printf '%s\n' "$_html_assets" | grep -oE 'href="[^"]*/releases/download/[^"]+"' | sed -e 's/^href="//' -e 's/"$//' -e 's/[?#].*//' | grep -E "$_pattern" | head -n 1 || true)
					if [ -n "$_url" ]; then
						case "$_url" in
						/*) _url="https://github.com${_url}" ;;
						esac
					fi
				fi
			fi

			[ -z "$_url" ] && {
				echo "fetch: Asset matching '$_pattern' not found for ${_repo}" >&2
				return 1
			}
			echo "$_url"
		else
			# Resolve latest tag via redirect for source tarballs
			_tag=$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${_repo}/releases/latest" 2>/dev/null | sed -e 's|.*/releases/tag/||' -e 's|.*/tag/||')
			[ -z "$_tag" ] && {
				echo "fetch: Failed to resolve latest tag for ${_repo}" >&2
				return 1
			}
			echo "https://github.com/${_repo}/archive/refs/tags/${_tag}.tar.gz"
		fi
		;;
	*)
		echo "fetch: Unsupported source scheme '$_source'" >&2
		return 1
		;;
	esac
}

# Download URL to a specific file
fetch_download() {
	_url="$1"
	_output="$2"
	mkdir -p "$(dirname "$_output")"
	curl -fsSL -o "$_output" "$_url"
}

# Portable extraction into a destination directory
# Extracts all formats cleanly without GNU/BSD tar flag incompatibilities
fetch_extract() {
	_archive="$1"
	_dest="$2"
	mkdir -p "$_dest"
	case "$_archive" in
	*.tar.gz | *.tgz)
		tar -xzf "$_archive" -C "$_dest"
		;;
	*.tar.xz)
		tar -xJf "$_archive" -C "$_dest"
		;;
	*.tar.zst)
		tar --zstd -xf "$_archive" -C "$_dest"
		;;
	*.tar.bz2)
		tar -xjf "$_archive" -C "$_dest"
		;;
	*.zip)
		unzip -q -o "$_archive" -d "$_dest"
		;;
	*.bz2)
		_name=$(basename "$_archive" .bz2)
		bunzip2 -c "$_archive" >"$_dest/$_name"
		;;
	*.gz)
		_name=$(basename "$_archive" .gz)
		gunzip -c "$_archive" >"$_dest/$_name"
		;;
	*)
		# Raw uncompressed executable
		_name=$(basename "$_archive")
		cp "$_archive" "$_dest/$_name"
		;;
	esac
}
