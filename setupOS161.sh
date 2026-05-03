#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$TOOLBUILD_DIR" "$TOOLS_DIR/bin" "$LOG_DIR"

# ── Pre-flight: verify fixedFiles are present before any build starts ─────────
FIXED_FILES=(
    "$SCRIPT_DIR/fixedFiles/reload1.c"
    "$SCRIPT_DIR/fixedFiles/sim-arange.h"
    "$SCRIPT_DIR/fixedFiles/onsel.h"
    "$SCRIPT_DIR/fixedFiles/usemtest.c"
)
_missing_fixed=0
for _f in "${FIXED_FILES[@]}"; do
    if [ ! -f "$_f" ]; then
        log_error "Missing required file: $_f"
        _missing_fixed=1
    fi
done
[ "$_missing_fixed" -eq 0 ] || die "fixedFiles are missing — is your repo checkout complete?"

export PATH="$TOOLS_DIR/bin:$PATH"

# ── Idempotency sentinels ─────────────────────────────────────────────────────
_sentinel_binutils="$TOOLS_DIR/bin/mips-harvard-os161-as"
_sentinel_gcc="$TOOLS_DIR/bin/mips-harvard-os161-gcc"
_sentinel_gdb="$TOOLS_DIR/bin/mips-harvard-os161-gdb"
_sentinel_sys161="$TOOLS_DIR/bin/sys161"
_sentinel_src="$OS161_DIR/src/configure"

# ── Build functions ───────────────────────────────────────────────────────────

_build_binutils() {
    rm -rf "$TOOLBUILD_DIR"/binutils-*
    tar -xf "$(find_tarball 'binutils-*.tar.gz')" -C "$TOOLBUILD_DIR"
    cd "$TOOLBUILD_DIR/binutils-2.24+os161-2.1"
    find . -name '*.info' | xargs -r touch
    touch intl/plural.c
    ./configure --nfp --disable-werror \
        --target=mips-harvard-os161 --prefix="$TOOLS_DIR"
    make $MAKE_FLAGS
    make install $MAKE_FLAGS
}

_build_gcc() {
    # gcc's ./contrib/download_prerequisites fetches GMP, MPFR, MPC at build
    # time — this requires a network connection during setupOS161.sh.
    rm -rf "$TOOLBUILD_DIR"/gcc-* "$TOOLBUILD_DIR/buildgcc"
    tar -xf "$(find_tarball 'gcc-*.tar.gz')" -C "$TOOLBUILD_DIR"
    cd "$TOOLBUILD_DIR/gcc-"*
    find . -name '*.info' | xargs -r touch
    find . -name '*.texi' | xargs -r touch
    touch intl/plural.c
    ./contrib/download_prerequisites
    cp "$SCRIPT_DIR/fixedFiles/reload1.c" ./gcc/reload1.c
    cd "$TOOLBUILD_DIR"
    mkdir buildgcc
    cd buildgcc
    ../gcc-*/configure \
        --enable-languages=c,lto \
        --nfp --disable-shared --disable-threads \
        --disable-libmudflap --disable-libssp \
        --disable-libstdcxx --disable-nls \
        --target=mips-harvard-os161 \
        --prefix="$TOOLS_DIR"
    make $MAKE_FLAGS MAKEINFO=true
    make install $MAKE_FLAGS MAKEINFO=true
}

_build_gdb() {
    rm -rf "$TOOLBUILD_DIR"/gdb-*
    tar -xf "$(find_tarball 'gdb-*.tar.gz')" -C "$TOOLBUILD_DIR"
    cd "$TOOLBUILD_DIR/gdb-"*
    find . -name '*.info' | xargs -r touch
    touch intl/plural.c
    cp "$SCRIPT_DIR/fixedFiles/sim-arange.h" ./sim/common/sim-arange.h
    ./configure \
        --target=mips-harvard-os161 \
        --prefix="$TOOLS_DIR" \
        --with-python=no
    make $MAKE_FLAGS
    make install $MAKE_FLAGS
}

_build_sys161() {
    rm -rf "$TOOLBUILD_DIR"/sys161-*
    tar -xf "$(find_tarball 'sys161-*.tar.gz')" -C "$TOOLBUILD_DIR"
    cd "$TOOLBUILD_DIR/sys161-"*
    cp "$SCRIPT_DIR/fixedFiles/onsel.h" ./include/onsel.h
    ./configure --prefix="$TOOLS_DIR" mipseb
    make $MAKE_FLAGS
    make install $MAKE_FLAGS
}

_extract_os161_src() {
    rm -rf "$OS161_DIR"/os161-base-* "$OS161_DIR/src"
    tar -xf "$(find_tarball 'os161-base-*.tar.gz')" -C "$OS161_DIR"
    mv "$OS161_DIR"/os161-base-* "$OS161_DIR/src"
    cp "$SCRIPT_DIR/fixedFiles/usemtest.c" \
        "$OS161_DIR/src/userland/testbin/usemtest/usemtest.c"
}

# ── Build orchestration ───────────────────────────────────────────────────────

if [ -f "$_sentinel_binutils" ]; then
    log_ok "Skipping binutils — already built ($_sentinel_binutils exists)"
else
    run_step "binutils" "$LOG_DIR/binutils.log" _build_binutils
fi

PARALLEL_FAILED=0
GCC_PID="" GDB_PID="" SYS161_PID="" SRC_PID=""

if [ -f "$_sentinel_gcc" ]; then
    log_ok "Skipping gcc    — already built"
else
    log_warn "gcc build will download GMP/MPFR/MPC via contrib/download_prerequisites — internet required"
    run_step_bg "gcc"       "$LOG_DIR/gcc.log"       _build_gcc
    GCC_PID=$!
fi

if [ -f "$_sentinel_gdb" ]; then
    log_ok "Skipping gdb    — already built"
else
    run_step_bg "gdb"       "$LOG_DIR/gdb.log"       _build_gdb
    GDB_PID=$!
fi

if [ -f "$_sentinel_sys161" ]; then
    log_ok "Skipping sys161 — already built"
else
    run_step_bg "sys161"    "$LOG_DIR/sys161.log"    _build_sys161
    SYS161_PID=$!
fi

if [ -f "$_sentinel_src" ]; then
    log_ok "Skipping os161 source extraction — already present"
else
    run_step_bg "os161-src" "$LOG_DIR/os161-src.log" _extract_os161_src
    SRC_PID=$!
fi

[ -f "$_sentinel_gcc"    ] || { [ -n "$GCC_PID"    ] || die "GCC_PID unset — logic error"; wait_step "gcc"       "$GCC_PID"    "$LOG_DIR/gcc.log"; }
[ -f "$_sentinel_gdb"    ] || { [ -n "$GDB_PID"    ] || die "GDB_PID unset — logic error"; wait_step "gdb"       "$GDB_PID"    "$LOG_DIR/gdb.log"; }
[ -f "$_sentinel_sys161" ] || { [ -n "$SYS161_PID" ] || die "SYS161_PID unset — logic error"; wait_step "sys161"    "$SYS161_PID" "$LOG_DIR/sys161.log"; }
[ -f "$_sentinel_src"    ] || { [ -n "$SRC_PID"    ] || die "SRC_PID unset — logic error"; wait_step "os161-src" "$SRC_PID"    "$LOG_DIR/os161-src.log"; }

[ "$PARALLEL_FAILED" -eq 0 ] || die "One or more parallel builds failed (see logs above)."

log_ok "Toolchain build complete.  Binaries in: $TOOLS_DIR/bin"
exit 0
