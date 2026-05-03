#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

log_info "Uninstalling os161..."
log_info "  Removing: $OS161_DIR"
log_info "  Removing: $SCRIPT_DIR/testbuild"
log_info "  Removing os161 PATH entry from rc files"

rm -rf "$OS161_DIR"

# Fix: remove testbuild/ which is created inside the repo by testBuild.sh
# and is not under $OS161_DIR, so it must be removed separately.
rm -rf "$SCRIPT_DIR/testbuild"

# Remove the marker line and the PATH export line added by setEnvPermanent.sh.
# Delete any line matching the marker comment OR the os161 PATH export,
# regardless of surrounding blank lines — no positional assumptions.
#
# Fix: setEnvPermanent.sh writes to .bashrc AND .bash_profile/.profile,
# so uninstall must clean all three — not only .bashrc.
_remove_from_rc() {
    local target="$1"
    [ -f "$target" ] || return 0
    if grep -q "os161/tools/bin" "$target" 2>/dev/null; then
        sed -i '/^[[:space:]]*$/{N; /^\n# os161 toolchain$/d}; /^# os161 toolchain$/d; /os161\/tools\/bin/d' "$target"
        if grep -q "os161/tools/bin" "$target" 2>/dev/null; then
            log_error "Failed to remove os161 PATH entry from $target — remove manually"
            return 1
        fi
        log_ok "Removed os161 PATH entry from $target"
    else
        log_info "No os161 PATH entry found in $target — nothing to remove"
    fi
}

_rc_failed=0
_remove_from_rc "$HOME/.bashrc"        || _rc_failed=1
_remove_from_rc "$HOME/.bash_profile"  || _rc_failed=1
_remove_from_rc "$HOME/.profile"       || _rc_failed=1
[ "$_rc_failed" -eq 0 ] || exit 1

log_ok "Uninstall complete."
log_warn "Logout/login to clear os161 from PATH in existing shells."

exit 0
