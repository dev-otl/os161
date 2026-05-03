#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$LOG_DIR"
chmod +x "$SCRIPT_DIR"/*.sh

_START=$(date +%s)
log_info "=== os161 install started ==="
log_info "Install root:    $OS161_DIR"
log_info "Downloads:       $DOWNLOAD_DIR"
log_info "Logs:            $LOG_DIR"
log_info "Make parallelism: -j${MAKE_JOBS} per component (override: MAKE_JOBS=N)"
printf '\n'

"$SCRIPT_DIR/preSetupOS161.sh"
printf '\n'
"$SCRIPT_DIR/downloadTarballs.sh"
printf '\n'
"$SCRIPT_DIR/setupOS161.sh"
printf '\n'
"$SCRIPT_DIR/testBuild.sh"
printf '\n'
"$SCRIPT_DIR/setEnvPermanent.sh"
printf '\n'

_END=$(date +%s)
_ELAPSED=$(( _END - _START ))
log_ok "=== os161 installed successfully in ${_ELAPSED}s ==="
log_info "Binaries: $TOOLS_DIR/bin"
log_info "Source:   $OS161_DIR/src"
log_warn "Logout/login required before PATH takes effect automatically."

exit 0
