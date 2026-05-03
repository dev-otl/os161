#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$LOG_DIR"
LOGFILE="$LOG_DIR/preSetup.log"

log_info "Checking/installing build dependencies..."
log_info "Log: $LOGFILE"

# Packages required to build the os161 toolchain.
REQUIRED_PKGS=(build-essential gdb libncurses-dev bmake)

MISSING=()
for pkg in "${REQUIRED_PKGS[@]}"; do
    # dpkg-query exits non-zero if the package is not installed.
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        MISSING+=("$pkg")
    else
        log_ok "Already installed: $pkg"
    fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then
    log_ok "All dependencies already installed — skipping apt"
    exit 0
fi

log_info "Installing missing packages: ${MISSING[*]}"

{
    # Only update the package index and install the specific missing packages.
    # Intentionally NOT running apt-get upgrade — that would upgrade every
    # installed package on the system, which is far beyond the scope of this
    # script and potentially dangerous on a non-fresh machine.
    sudo apt-get update
    sudo apt-get install -y "${MISSING[@]}"
} >> "$LOGFILE" 2>&1 || {
    log_error "apt failed — see $LOGFILE"
    tail -n 20 "$LOGFILE" >&2
    exit 1
}

log_ok "Dependencies installed: ${MISSING[*]}"
exit 0
