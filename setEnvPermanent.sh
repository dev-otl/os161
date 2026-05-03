#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PROFILE_SCRIPT="/etc/profile.d/os161.sh"

# Pre-condition: the toolchain must have been built before we can write a
# permanent path.  Fail early with a clear message rather than writing a
# broken path to /etc/profile.d.
if [ ! -d "$TOOLS_DIR/bin" ]; then
    die "Tools directory not found: $TOOLS_DIR/bin — run setupOS161.sh first"
fi
OS161_BINPATH=$(realpath "$TOOLS_DIR/bin")
EXPECTED_LINE="export PATH=\$PATH:$OS161_BINPATH"

# ── Idempotency ───────────────────────────────────────────────────────────────
if [ -f "$PROFILE_SCRIPT" ] && grep -qF "$OS161_BINPATH" "$PROFILE_SCRIPT"; then
    log_ok "PATH already configured in $PROFILE_SCRIPT — nothing to do"
else
    log_info "Writing $PROFILE_SCRIPT ..."
    echo "$EXPECTED_LINE" | sudo tee "$PROFILE_SCRIPT" > /dev/null
    log_ok "Wrote: $PROFILE_SCRIPT"
fi

printf '\n'
log_info "To use os161 immediately in this shell without logging out, run:"
printf '    export PATH=$PATH:%s\n\n' "$OS161_BINPATH"
log_info "Or source the profile script directly:"
printf '    source %s\n\n' "$PROFILE_SCRIPT"
log_warn "A logout/login (or shell restart) is required to pick up the change automatically."

exit 0
