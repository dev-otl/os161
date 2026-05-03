#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

log_info "Uninstalling os161..."
log_info "  Removing: $OS161_DIR"
log_info "  Removing: /etc/profile.d/os161.sh"

rm -rf "$OS161_DIR"           # user-owned; no sudo needed
sudo rm -f /etc/profile.d/os161.sh  # written with sudo, so needs sudo to remove

log_ok "Uninstall complete."
log_warn "Logout/login to clear os161 from PATH in existing shells."

exit 0
