#!/bin/sh
set -eu

# Detect the OS and Distribution
_uname_s=$(uname -s)

case "$_uname_s" in
Linux)
	# 1. Android Termux
	if [ -d "/data/data/com.termux" ] || command -v termux-info >/dev/null 2>&1; then
		OS="android"
		DISTRO="termux"
	# 2. Alpine Linux
	elif [ -f "/etc/alpine-release" ]; then
		OS="linux"
		DISTRO="alpine"
	# 3. Debian / Ubuntu / Devuan
	elif [ -f "/etc/debian_version" ]; then
		OS="linux"
		DISTRO="debian"
	# 4. Fallback Linux
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

# Detect machine architecture
UNAME_M=$(uname -m)

case "$UNAME_M" in
x86_64) ARCH="amd64" ;;
aarch64 | arm64) ARCH="arm64" ;;
armv7l) ARCH="armhf" ;;
i386 | i686) ARCH="386" ;;
*) ARCH="$UNAME_M" ;;
esac

export OS DISTRO ARCH
