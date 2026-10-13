#!/bin/sh
# fetch.sh - Shared POSIX engine for binary resolution, downloading, and unpacking
set -eu

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
