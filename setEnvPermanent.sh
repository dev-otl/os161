#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

# Pre-condition: toolchain must be built first
if [ ! -d "$TOOLS_DIR/bin" ]; then
    die "Tools directory not found: $TOOLS_DIR/bin — run setupOS161.sh first"
fi

# Build the PATH line using the actual install location.
if [[ "$TOOLS_DIR" == "$HOME"* ]]; then
    _REL="${TOOLS_DIR#"$HOME"}"
    PROFILE_LINE="export PATH=\$PATH:\$HOME${_REL}/bin"
else
    PROFILE_LINE="export PATH=\$PATH:$TOOLS_DIR/bin"
fi

MARKER="# os161 toolchain"

_append_to_file() {
    local target="$1"
    if grep -qF "os161/tools/bin" "$target" 2>/dev/null; then
        log_ok "PATH already configured in $target — nothing to do"
    else
        {
            printf '\n'
            printf '%s\n' "$MARKER"
            printf '%s\n' "$PROFILE_LINE"
        } >> "$target"
        log_ok "Added to $target: $PROFILE_LINE"
    fi
}

# .bashrc  — non-login interactive shells (most terminal emulators)
_append_to_file "$HOME/.bashrc"

# .bash_profile / .profile — login shells (SSH, console login, macOS Terminal)
# Only write to whichever file actually exists; prefer .bash_profile.
if [ -f "$HOME/.bash_profile" ]; then
    _append_to_file "$HOME/.bash_profile"
elif [ -f "$HOME/.profile" ]; then
    _append_to_file "$HOME/.profile"
fi

# Apply to the current shell session immediately.
export PATH="$PATH:$TOOLS_DIR/bin"
log_ok "PATH updated in current shell session"

log_warn "New terminal windows will pick up the PATH automatically."
log_warn "To apply in THIS terminal right now: source ~/.bashrc"

exit 0
