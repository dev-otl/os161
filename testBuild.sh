#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

TESTBUILD_DIR="$SCRIPT_DIR/testbuild"
TEST_OSTREE="$TESTBUILD_DIR/root"
TEST_SRC_DIR="$TESTBUILD_DIR/src"
KERNEL_BIN="$TEST_OSTREE/kernel"
BMAKE_FLAGS="-j${MAKE_JOBS}"

mkdir -p "$LOG_DIR"
export PATH="$TOOLS_DIR/bin:$PATH"

# ── Idempotency ───────────────────────────────────────────────────────────────
if [ -f "$KERNEL_BIN" ]; then
    log_ok "Test kernel already built ($KERNEL_BIN) — skipping build"
    log_info "Re-running sys161 boot test..."
else
    log_info "Test build directory: $TESTBUILD_DIR"
    log_info "Logs: $LOG_DIR/testBuild-*.log"

    _setup_src() {
        rm -rf "$TESTBUILD_DIR"
        mkdir -p "$TEST_OSTREE"
        tar -xf "$(find_tarball 'os161-base-*.tar.gz')" -C "$TESTBUILD_DIR"
        mv "$TESTBUILD_DIR"/os161-base-* "$TEST_SRC_DIR"
        cp "$SCRIPT_DIR/fixedFiles/usemtest.c" \
            "$TEST_SRC_DIR/userland/testbin/usemtest/usemtest.c"
        cd "$TEST_SRC_DIR"
        ./configure --ostree="$TEST_OSTREE"
        bmake $BMAKE_FLAGS
        bmake $BMAKE_FLAGS install
    }
    run_step "test: configure + userland" "$LOG_DIR/testBuild-userland.log" _setup_src

    _build_kernel() {
        cd "$TEST_SRC_DIR/kern/conf"
        ./config DUMBVM
        cd ../compile/DUMBVM
        bmake $BMAKE_FLAGS depend
        bmake $BMAKE_FLAGS
        bmake $BMAKE_FLAGS install
    }
    run_step "test: DUMBVM kernel" "$LOG_DIR/testBuild-kernel.log" _build_kernel

    cp "$TOOLS_DIR/share/examples/sys161/sys161.conf.sample" "$TEST_OSTREE/sys161.conf"

    _create_disks() {
        cd "$TEST_OSTREE"
        disk161 create LHD0.img 5M
        disk161 create LHD1.img 5M
    }
    run_step "test: create disks" "$LOG_DIR/testBuild-disks.log" _create_disks
fi

# Boot test — always run even if build was skipped, so a re-run re-verifies.
log_info "Booting DUMBVM kernel with sys161 (should start and shut down cleanly)..."
cd "$TEST_OSTREE"
sys161 kernel 's;q'
log_ok "sys161 boot test passed."

exit 0
