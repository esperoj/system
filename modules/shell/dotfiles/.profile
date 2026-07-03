# --- 1. THE GUARD (Source Only Once) ---
if [ -n "$_PROFILE_SOURCED" ]; then
    return 0
fi
export _PROFILE_SOURCED=1

# Debug message (visible during login/manual source)
echo "Running ${HOME}/.profile"

# --- 2. BASE ENVIRONMENT ---
export MACHINE_TYPE=""
export EDITOR="emacs" # Fitting for your workflow

# Load main .env if it exists
if [ -f "${HOME}/.env" ]; then
    set -a; . "${HOME}/.env"; set +a
fi

# ASDF Version Manager
if [ -d "$HOME/.asdf" ]; then
    . "$HOME/.asdf/asdf.sh"
fi

# --- 3. PATH & LIBRARY HELPERS ---
# Idempotent LD_LIBRARY_PATH
case ":$LD_LIBRARY_PATH:" in
    *":$HOME/.local/lib:"*) ;;
    *) export LD_LIBRARY_PATH="$HOME/.local/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ;;
esac

# --- 4. HOST/MACHINE SPECIFIC LOGIC ---
_HOSTNAME=$(hostname)

# Pubnix / Temporary Directory Logic
if [ "$MACHINE_TYPE" = "pubnix" ]; then
    case "$_HOSTNAME" in
        "core.envs.net"|"de1"|"verntil")
            export TMPDIR="/run/user/$(id -u)/tmp" ;;
        *)
            export TMPDIR="/tmp/$(whoami)" ;;
    esac

    if [ ! -d "${TMPDIR}" ]; then
        mkdir -p "${TMPDIR}"
        chmod 700 "${TMPDIR}"
        for dir in .cache .cargo .npm tmp; do
            mkdir -p "${TMPDIR}/$dir"
            rm -rf "${HOME}/$dir"
            ln -s "${TMPDIR}/$dir" "${HOME}/$dir"
        done
    fi
fi

# BSD Python Paths
if [ "$_HOSTNAME" = "bsd.tilde.team" ]; then
    # POSIX way to expand glob into variable
    for _py_path in "${HOME}"/.local/lib/python3.*/site-packages; do
        if [ -d "$_py_path" ]; then
            export PYTHONPATH="${PYTHONPATH}${PYTHONPATH:+:}$_py_path"
        fi
        break
    done
fi

# --- 5. AUTOMATION FUNCTIONS ---

# Load modular env files
load_all_envs() {
    _env_dir="$HOME/.config/env"
    if [ -d "$_env_dir" ]; then
        for _f in "$_env_dir"/*.env; do
            [ -f "$_f" ] || continue
            set -a; . "$_f"; set +a
        done
    fi
}
load_all_envs

# Vault Initialization
if [ -n "$VAULT_CHECKOUT_DIR" ] && [ ! -d "$VAULT_CHECKOUT_DIR" ]; then
    vault open git ssh rclone base
    # Secure files immediately
    find "$VAULT_CHECKOUT_DIR" -type f ! -executable -exec chmod 600 {} +
fi

# Clean up local variables
unset _HOSTNAME _py_path
