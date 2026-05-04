#!/bin/bash
# testBuild.sh — builds the DUMBVM kernel against the real os161 root directory
# and verifies the toolchain by booting it under sys161.
# Requires setupRoot.sh to have run first.
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$LOG_DIR"
export PATH="$TOOLS_DIR/bin:$PATH"

BMAKE_FLAGS="-j${MAKE_JOBS}"
KERNEL_BIN="$OS161_DIR/root/kernel"

# Pre-condition
[ -f "$OS161_DIR/root/sys161.conf" ] \
    || die "Root directory not configured — run setupRoot.sh first"

# ── Build DUMBVM kernel (idempotent: skip if already present) ─────────────────
if [ -f "$KERNEL_BIN" ]; then
    log_ok "DUMBVM kernel already built ($KERNEL_BIN) — skipping build"
    log_info "Re-running sys161 boot test..."
else
    _build_kernel() {
        cd "$OS161_DIR/src/kern/conf"
        ./config DUMBVM
        cd ../compile/DUMBVM
        bmake $BMAKE_FLAGS depend
        bmake $BMAKE_FLAGS
        bmake $BMAKE_FLAGS install
    }
    run_step "DUMBVM kernel" "$LOG_DIR/testBuild-kernel.log" _build_kernel
fi

# ── Boot test ─────────────────────────────────────────────────────────────────
log_info "Booting DUMBVM kernel with sys161 (should start and shut down cleanly)..."
cd "$OS161_DIR/root"
sys161 kernel 's;q'
log_ok "sys161 boot test passed."

exit 0
