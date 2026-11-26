case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH="$PATH:$HOME/projects/pkit/scripts"
case ":${LD_LIBRARY_PATH:-}:" in
    *":$HOME/.local/lib:"*) ;;
    *) export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
esac

load_all_envs() {
    _env_dir="$HOME/.config/env"
    if [ -f "$_env_dir/base.env" ]; then
        set -a; . "$_env_dir/base.env"; set +a
    fi
    if [ -d "$_env_dir" ]; then
        for _f in "$_env_dir"/*.env; do
            [ -f "$_f" ] || continue
            [ "$_f" = "$_env_dir/base.env" ] && continue
            set -a; . "$_f"; set +a
        done
    fi
}

load_all_envs

# Bash completions wherever bash runs interactively, with or without the
# bash-completion package (>= 2.12 loads this same directory lazily on its
# own): make's target completion (this module, quiet outside the system
# repo) plus whatever the modules installed user-locally — rclone, restic,
# git, written by the `completion` CLI (README, Daily operation). Sourced
# from here — not from .bashrc — because .bashrc already chains through
# .profile, so login and non-login shells get each file exactly once:
# Debian desktop, Termux phone, rootless pubnix alike.
if [ -n "${BASH_VERSION:-}" ] && [ -d "$HOME/.local/share/bash-completion/completions" ]; then
    for _comp in "$HOME/.local/share/bash-completion/completions"/*; do
        [ -f "$_comp" ] || continue
        . "$_comp"
    done
fi

_HOSTNAME=$(hostname 2>/dev/null || uname -n)

if [ -n "${TERMUX_VERSION:-}" ]; then
    export TMPDIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
elif [ "$MACHINE_TYPE" = "pubnix" ]; then
    case "$_HOSTNAME" in
        "core.envs.net"|"de1"|"verntil") export TMPDIR="/run/user/$(id -u)/tmp" ;;
        *)                               export TMPDIR="/tmp/$(whoami)" ;;
    esac

    if [ ! -d "${TMPDIR}" ]; then
        mkdir -p "${TMPDIR}" && chmod 700 "${TMPDIR}"
    fi
fi

if [ "$_HOSTNAME" = "bsd.tilde.team" ]; then
    for _py_path in "${HOME}"/.local/lib/python3.*/site-packages; do
        if [ -d "$_py_path" ]; then
            export PYTHONPATH="${PYTHONPATH:-}${PYTHONPATH:+:}$_py_path"
            break
        fi
    done
fi

unset _HOSTNAME _py_path _env_dir _f _comp
