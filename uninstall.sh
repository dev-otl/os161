#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

log_info "Uninstalling os161..."
log_info "  Removing: $OS161_DIR"
log_info "  Removing os161 PATH entry from $HOME/.bashrc"

rm -rf "$OS161_DIR"

# Remove the marker line and the PATH export line added by setEnvPermanent.sh.
# The marker is "# os161 toolchain"; the export line immediately follows it.
BASHRC="$HOME/.bashrc"
if grep -q "os161/tools/bin" "$BASHRC" 2>/dev/null; then
    sed -i '/# os161 toolchain/,+1d' "$BASHRC"
    log_ok "Removed os161 PATH entry from $BASHRC"
else
    log_info "No os161 PATH entry found in $BASHRC — nothing to remove"
fi

log_ok "Uninstall complete."
log_warn "Logout/login to clear os161 from PATH in existing shells."

exit 0
