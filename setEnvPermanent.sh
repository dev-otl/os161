#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

# Pre-condition: toolchain must be built first
if [ ! -d "$TOOLS_DIR/bin" ]; then
    die "Tools directory not found: $TOOLS_DIR/bin — run setupOS161.sh first"
fi

# Build the PATH line using the actual install location.
# If TOOLS_DIR is under $HOME, express it as $HOME/... so the line stays
# valid if the username changes (e.g. on another machine with the same layout).
# Otherwise fall back to the absolute path.
if [[ "$TOOLS_DIR" == "$HOME"* ]]; then
    _REL="${TOOLS_DIR#"$HOME"}"
    PROFILE_LINE="export PATH=\$PATH:\$HOME${_REL}/bin"
else
    PROFILE_LINE="export PATH=\$PATH:$TOOLS_DIR/bin"
fi

BASHRC="$HOME/.bashrc"
MARKER="# os161 toolchain"

# ── Idempotency ───────────────────────────────────────────────────────────────
if grep -qF "os161/tools/bin" "$BASHRC" 2>/dev/null; then
    log_ok "PATH already configured in $BASHRC — nothing to do"
else
    {
        printf '\n'
        printf '%s\n' "$MARKER"
        printf '%s\n' "$PROFILE_LINE"
    } >> "$BASHRC"
    log_ok "Added to $BASHRC: $PROFILE_LINE"
fi

# Also apply to the current shell session immediately — no logout needed.
export PATH="$PATH:$TOOLS_DIR/bin"
log_ok "PATH updated in current shell session"

log_warn "New terminal windows will pick up the PATH automatically."
log_warn "To apply in THIS terminal right now: source ~/.bashrc"

exit 0
