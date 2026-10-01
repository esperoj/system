#!/bin/sh
# fetch.sh - Shared POSIX engine for binary resolution, downloading, and unpacking
set -eu

# Resolve input to a concrete download URL
# Supports:
#   - Direct HTTP/HTTPS URLs (passthrough)
#   - GitHub repos via "gh:owner/repo" [regex] (resolves tag & asset via HTML endpoint)
fetch_resolve_url() {
    _source="$1"
    _pattern="${2:-}"

    case "$_source" in
        http://*|https://*)
            echo "$_source"
            ;;
        gh:*)
            _repo="${_source#gh:}"
            # 1. Resolve latest tag via HTTP redirect (zero API call, zero rate limit)
            _tag=$(curl -fsSIL -o /dev/null -w '%{url_effective}' "https://github.com/${_repo}/releases/latest" 2>/dev/null | sed 's|.*/tag/||')
            [ -z "$_tag" ] && { echo "fetch: Failed to resolve latest tag for ${_repo}" >&2; return 1; }

            if [ -n "$_pattern" ]; then
                # 2. Extract asset link matching regex from expanded assets HTML
                _asset_path=$(curl -fsSL "https://github.com/${_repo}/releases/expanded_assets/${_tag}" 2>/dev/null \
                    | grep -o "/${_repo}/releases/download/[^\"]*" \
                    | grep -E "$_pattern" \
                    | head -n 1)

                [ -z "$_asset_path" ] && { echo "fetch: Asset matching '$_pattern' not found for ${_repo} (${_tag})" >&2; return 1; }
                echo "https://github.com${_asset_path}"
            else
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
    curl -fsSL -o "$_output" "$_url"
}

# Portable extraction into a destination directory
# Extracts all formats cleanly without GNU/BSD tar flag incompatibilities
fetch_extract() {
    _archive="$1"
    _dest="$2"
    mkdir -p "$_dest"

    case "$_archive" in
        *.tar.gz|*.tgz)
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
            bunzip2 -c "$_archive" > "$_dest/$_name"
            ;;
        *.gz)
            _name=$(basename "$_archive" .gz)
            gunzip -c "$_archive" > "$_dest/$_name"
            ;;
        *)
            # Raw uncompressed executable
            _name=$(basename "$_archive")
            cp "$_archive" "$_dest/$_name"
            ;;
    esac
}
