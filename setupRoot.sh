#!/bin/bash
# setupRoot.sh — configures the os161 source tree and creates the working root
# directory at $OS161_DIR/root. Safe to re-run: exits early if already done.
# Run setupOS161.sh first (toolchain + source extraction must be complete).
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$LOG_DIR"
export PATH="$TOOLS_DIR/bin:$PATH"

BMAKE_FLAGS="-j${MAKE_JOBS}"

# Pre-conditions
[ -f "$OS161_DIR/src/configure" ] \
    || die "os161 source not found at $OS161_DIR/src — run setupOS161.sh first"
[ -x "$TOOLS_DIR/bin/mips-harvard-os161-gcc" ] \
    || die "Toolchain not found at $TOOLS_DIR/bin — run setupOS161.sh first"

# Sentinel: sys161.conf marks a fully configured root directory.
# (It is the last thing written, so its presence means all prior steps succeeded.)
_sentinel="$OS161_DIR/root/sys161.conf"

if [ -f "$_sentinel" ]; then
    log_ok "Root directory already configured ($OS161_DIR/root) — skipping"
    log_info "To reconfigure from scratch, remove $OS161_DIR/root and re-run this script."
    exit 0
fi

mkdir -p "$OS161_DIR/root"

# ── 1. Configure the source tree and build + install userland ─────────────────
_configure_src() {
    cd "$OS161_DIR/src"
    ./configure --ostree="$OS161_DIR/root"
    bmake $BMAKE_FLAGS
    bmake $BMAKE_FLAGS install
}
run_step "configure + build userland" "$LOG_DIR/setupRoot-userland.log" _configure_src

# ── 2. Create the disk images sys161 expects ──────────────────────────────────
_create_disks() {
    cd "$OS161_DIR/root"
    rm -f LHD0.img LHD1.img
    disk161 create LHD0.img 5M
    disk161 create LHD1.img 5M
}
run_step "create disk images" "$LOG_DIR/setupRoot-disks.log" _create_disks

# ── 3. Install the sys161 configuration file (sentinel — written last) ────────
cp "$TOOLS_DIR/share/examples/sys161/sys161.conf.sample" "$_sentinel"
log_ok "Installed sys161.conf → $OS161_DIR/root/sys161.conf"

log_ok "Root directory ready: $OS161_DIR/root"

# ── 4. Install VS Code workspace config (optional — skip if not present) ──────
_VSCODE_SRC="$SCRIPT_DIR/vscode-config"
_VSCODE_DST="$OS161_DIR/.vscode"
if [ -d "$_VSCODE_SRC" ]; then
    rm -rf "$_VSCODE_DST"
    cp -r "$_VSCODE_SRC" "$_VSCODE_DST"
    log_ok "VS Code config installed → $_VSCODE_DST"
    log_info "Open VS Code at: $OS161_DIR"
fi

log_info "Next: build a kernel with  bmake  inside  $OS161_DIR/src/kern/compile/<CONFIG>"

exit 0
