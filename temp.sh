#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> [1/5] Patching configure and sys-pkgs race conditions..."

cat <<'EOF' > configure
#!/bin/sh
set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <target1> [target2...]"
    exit 1
fi

# Reset state once cleanly before parallel execution
KV_STORE="${KV_STORE:-$(pwd)/.kv-store}"
rm -rf "$KV_STORE"
mkdir -p "$KV_STORE"

MAKE_TARGETS=""
for arg in "$@"; do
    MAKE_TARGETS="$MAKE_TARGETS ${arg}-cfg"
done

echo "==> Configuring node state: make$MAKE_TARGETS"
# shellcheck disable=SC2086
make $MAKE_TARGETS
EOF
chmod +x configure

# Remove destructive wipe from sys-pkgs/Makefile
cat <<'EOF' > modules/sys-pkgs/Makefile
.PHONY: sys-pkgs sys-pkgs-cfg
sys-pkgs:
	"$(MODULES_DIR)/sys-pkgs/setup"
sys-pkgs-cfg:
	@mkdir -p "$(KV_STORE)"
EOF

# Update sys-pkgs/setup to check common, distro-specific, and legacy apt keys
cat <<'EOF' > modules/sys-pkgs/setup
#!/bin/sh
set -eu

. "${LIB_DIR}/sh/os.sh"

case "$DISTRO" in
    termux)  MGR="pkg" ;;
    alpine)  MGR="apk" ;;
    debian)  MGR="apt" ;;
    freebsd) MGR="pkg" ;;
    *)
        echo "Notice: Distro '$DISTRO' not managed via system packages. Relying on fetch-bin/user-space." >&2
        exit 0
        ;;
esac

if [ "$DISTRO" != "termux" ] && [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "Notice: Insufficient privileges (not root and no passwordless sudo). Skipping system packages." >&2
    exit 0
fi

COMMON_PKGS=$(kv smembers "common-pkgs" 2>/dev/null || true)
DISTRO_PKGS=$(kv smembers "${DISTRO}-pkgs" 2>/dev/null || true)

# Backward-compatibility fallback for legacy apt keys
APT_PKGS=""
if [ "$DISTRO" = "debian" ]; then
    APT_PKGS=$(kv smembers "apt-pkgs" 2>/dev/null || true)
fi

ALL_PKGS=$(printf '%s %s %s' "$COMMON_PKGS" "$DISTRO_PKGS" "$APT_PKGS" | tr -s ' ' | sed 's/^ //;s/ $//')

if [ -n "$ALL_PKGS" ]; then
    echo ":: Bulk installing packages for [$DISTRO] via [$MGR]: $ALL_PKGS"
    # shellcheck disable=SC2086
    install-sys-pkg $ALL_PKGS
fi
EOF
chmod +x modules/sys-pkgs/setup

echo "==> [2/5] Refactoring module Makefiles for common vs. distro package sets..."

# 7zip
cat <<'EOF' > modules/7zip/Makefile
.PHONY: 7zip 7zip-cfg
7zip: sys-pkgs
	"$(MODULES_DIR)/7zip/install"
7zip-cfg: sys-pkgs-cfg
	@kv sadd debian-pkgs 7zip
	@kv sadd termux-pkgs p7zip
EOF

# Age
cat <<'EOF' > modules/age/Makefile
.PHONY: age age-cfg
age: sys-pkgs stow
	"$(MODULES_DIR)/age/install"
	mkdir -p ~/.config/age
	MODULES_DIR="$(MODULES_DIR)/age" dot apply dotfiles
age-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd common-pkgs age
EOF

# Base
cat <<'EOF' > modules/base/Makefile
.PHONY: base base-cfg
BASE_DEPS=7zip age bin env git jq lib rclone shell ssh stow vault recipes
base: sys-pkgs $(BASE_DEPS)
base-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(BASE_DEPS))
	@kv sadd common-pkgs parallel ca-certificates coreutils curl findutils gawk make moreutils sed sudo time wget unzip xz-utils zstd
	@kv sadd debian-pkgs openssh-client gpg rename iputils-ping
	@kv sadd termux-pkgs openssh gnupg
	@mkdir -p "$$HOME/.config/env"
EOF

# Dev
cat <<'EOF' > modules/dev/Makefile
.PHONY: dev dev-cfg
dev: sys-pkgs stow ocaml
	MODULES_DIR="$(MODULES_DIR)/dev" dot apply dotfiles
dev-cfg: sys-pkgs-cfg .WAIT stow-cfg ocaml-cfg
	@kv sadd common-pkgs fzf tmux vim ripgrep shellcheck shfmt jq
	@kv sadd debian-pkgs build-essential patch bats nodejs npm python3 python3-pip pipx python3-venv
	@kv sadd termux-pkgs clang make python nodejs-lts
EOF

# Git
cat <<'EOF' > modules/git/Makefile
.PHONY: git git-cfg
git: sys-pkgs ssh
git-cfg: sys-pkgs-cfg .WAIT ssh-cfg
	@kv sadd common-pkgs git
EOF

# SSH
cat <<'EOF' > modules/ssh/Makefile
.PHONY: ssh ssh-cfg
ssh: sys-pkgs stow
	mkdir -p ~/.ssh
	MODULES_DIR="$(MODULES_DIR)/ssh" dot apply dotfiles
ssh-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd debian-pkgs openssh-client
	@kv sadd alpine-pkgs openssh
	@kv sadd termux-pkgs openssh
EOF

# Crontab
cat <<'EOF' > modules/crontab/Makefile
.PHONY: crontab crontab-cfg
crontab: sys-pkgs stow
	MODULES_DIR="$(MODULES_DIR)/crontab" dot apply dotfiles
	crontab "$${HOME}/.config/crontab/crontab"
crontab-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd debian-pkgs cron
	@kv sadd termux-pkgs cronie
EOF

# Firefox
cat <<'EOF' > modules/firefox/Makefile
.PHONY: firefox firefox-cfg
firefox: sys-pkgs
firefox-cfg: sys-pkgs-cfg
	@kv sadd debian-pkgs firefox-esr
EOF

# KeepassXC
cat <<'EOF' > modules/keepassxc/Makefile
.PHONY: keepassxc keepassxc-cfg
keepassxc: sys-pkgs
keepassxc-cfg: sys-pkgs-cfg
	@kv sadd debian-pkgs keepassxc
EOF

# Emacs
cat <<'EOF' > modules/emacs/Makefile
.PHONY: emacs emacs-cfg
emacs: stow sys-pkgs
	mkdir -p ~/.config/emacs
	MODULES_DIR="$(MODULES_DIR)/emacs" dot apply dotfiles
emacs-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd common-pkgs pandoc
	@kv sadd debian-pkgs emacs-gtk elpa-markdown-mode elpa-magit elpa-tuareg
	@kv sadd termux-pkgs emacs
EOF

# Desktop
cat <<'EOF' > modules/desktop/Makefile
.PHONY: desktop desktop-cfg
DESKTOP_DEPS = stow base dev anki keepassxc firefox emacs crontab wireproxy
desktop: sys-pkgs $(DESKTOP_DEPS)
	MODULES_DIR="$(MODULES_DIR)/desktop" dot apply dotfiles
desktop-cfg: sys-pkgs-cfg .WAIT $(addsuffix -cfg,$(DESKTOP_DEPS))
	@kv sadd common-pkgs tk tcl
	@kv sadd debian-pkgs bleachbit redshift-gtk gvfs-backends gvfs-fuse mtp-tools
	@kv sadd vault-modules ssh base git rclone
EOF

# Shell
cat <<'EOF' > modules/shell/Makefile
.PHONY: shell shell-cfg
shell: stow
	MODULES_DIR="$(MODULES_DIR)/shell" dot apply dotfiles
shell-cfg: sys-pkgs-cfg .WAIT stow-cfg
	@kv sadd common-pkgs bash
EOF

echo "==> [3/5] Generating missing backup script (Axiom 3)..."

cat <<'EOF' > modules/bin/dotfiles/.local/bin/backup
#!/bin/sh
# backup - Cold streaming age-encrypted archive creator & unpacker
set -eu

usage() {
    cat <<USAGE >&2
Usage:
  backup create <source-dir> <output-file.tar.gz.age> [age-recipient]
  backup restore <input-file.tar.gz.age> <destination-dir> [age-identity-file]
USAGE
    exit 1
}

[ $# -ge 2 ] || usage

ACTION="$1"
shift

case "$ACTION" in
    create)
        SRC="${1:-}"
        DEST="${2:-}"
        RECIPIENT="${3:-${AGE_RECIPIENTS:-}}"

        [ -d "$SRC" ] || { echo "Error: Source directory '$SRC' does not exist." >&2; exit 1; }
        [ -n "$DEST" ] || usage

        if [ -z "$RECIPIENT" ] && [ -f "$HOME/.config/age/recipients.txt" ]; then
            RECIPIENT=$(grep -v '^#' "$HOME/.config/age/recipients.txt" | head -n 1)
        fi
        [ -n "$RECIPIENT" ] || { echo "Error: No Age recipient key provided or found." >&2; exit 1; }

        mkdir -p "$(dirname "$DEST")"
        echo ":: Archiving and encrypting $SRC -> $DEST..."
        tar -C "$(dirname "$SRC")" -czf - "$(basename "$SRC")" | age -r "$RECIPIENT" -o "$DEST"
        echo "✓ Successfully created encrypted archive: $DEST"
        ;;

    restore)
        SRC="${1:-}"
        DEST="${2:-}"
        IDENTITY="${3:-${AGE_IDENTITIES_FILE:-$HOME/.config/age/keys.txt}}"

        [ -f "$SRC" ] || { echo "Error: Encrypted archive '$SRC' not found." >&2; exit 1; }
        [ -n "$DEST" ] || usage
        [ -f "$IDENTITY" ] || { echo "Error: Age identity key '$IDENTITY' not found." >&2; exit 1; }

        mkdir -p "$DEST"
        echo ":: Decrypting and unpacking $SRC -> $DEST..."
        age -d -i "$IDENTITY" "$SRC" | tar -C "$DEST" --strip-components=1 -xzf -
        echo "✓ Successfully restored archive into: $DEST"
        ;;

    *)
        usage
        ;;
esac
EOF
chmod 755 modules/bin/dotfiles/.local/bin/backup

echo "==> [4/5] Fixing script pathing, vimrc portability, and bashrc guards..."

# Fix fetch-bin relative fallback path
sed -i 's|\.\./\.\./lib/dotfiles|\.\./\.\./\.\./lib/dotfiles|g' modules/bin/dotfiles/.local/bin/fetch-bin

# Fix bashrc cargo check
sed -i 's|\. "$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& \. "$HOME/.cargo/env"|g' modules/shell/dotfiles/.bashrc

# Fix vimrc hardcoded /home/esperoj
sed -i 's|/home/esperoj/\.opam|$HOME/\.opam|g' modules/dev/dotfiles/.vimrc

# Remove dead setup script
rm -f modules/bin/dotfiles/.local/bin/setup

echo "==> [5/5] Migration completed successfully."
