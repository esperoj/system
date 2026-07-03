#!/bin/sh

# Detect the OS
_uname_s=$(uname -s)

case "$_uname_s" in
    Linux)
        # Check for Android specifically
        # Android's linker or getprop are reliable indicators
        if command -v getprop >/dev/null 2>&1 || [ -d "/system/app" ]; then
            OS="android"
        else
            OS="linux"
        fi
        ;;
    FreeBSD)
        OS="freebsd"
        ;;
    *)
        OS="unknown"
        ;;
esac
# Detect machine architecture
UNAME_M=$(uname -m)

case "$UNAME_M" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    armv7l)
        ARCH="armhf"
        ;;
    i386|i686)
        ARCH="386"
        ;;
    *)
        ARCH="$UNAME_M"
        ;;
esac

export OS ARCH
