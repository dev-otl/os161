#!/bin/bash
# checkInstall.sh — verifies the os161 toolchain is correctly installed
# Run from the same directory as install.sh

set -uo pipefail   # no -e: we want to collect ALL failures, not stop at first

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

PASS=0
FAIL=0

_pass() { log_ok  "$1"; (( PASS++ )) || true; }
_fail() { log_error "$1"; (( FAIL++ )) || true; }

# ── 1. Required binaries exist and are executable ─────────────────────────────
echo ""
log_info "--- Checking binaries ---"

BINS=(
    mips-harvard-os161-as
    mips-harvard-os161-gcc
    mips-harvard-os161-gdb
    mips-harvard-os161-ld
    mips-harvard-os161-objdump
    sys161
    disk161
)

for bin in "${BINS[@]}"; do
    path="$TOOLS_DIR/bin/$bin"
    if [ -x "$path" ]; then
        _pass "$bin  ($path)"
    else
        _fail "$bin  NOT FOUND at $path"
    fi
done

# ── 2. Binaries are MIPS cross-tools (not native) ────────────────────────────
echo ""
log_info "--- Checking binary targets ---"

GCC_BIN="$TOOLS_DIR/bin/mips-harvard-os161-gcc"
if [ -x "$GCC_BIN" ]; then
    target=$("$GCC_BIN" -dumpmachine 2>/dev/null)
    if [ "$target" = "mips-harvard-os161" ]; then
        _pass "gcc target: $target"
    else
        _fail "gcc target is '$target', expected 'mips-harvard-os161'"
    fi

    version=$("$GCC_BIN" --version 2>/dev/null | head -n 1)
    _pass "gcc version: $version"
fi

GDB_BIN="$TOOLS_DIR/bin/mips-harvard-os161-gdb"
if [ -x "$GDB_BIN" ]; then
    version=$("$GDB_BIN" --version 2>/dev/null | head -n 1)
    _pass "gdb version: $version"
fi

SYS161_BIN="$TOOLS_DIR/bin/sys161"
if [ -x "$SYS161_BIN" ]; then
    version=$("$SYS161_BIN" --version 2>/dev/null | head -n 1 || true)
    _pass "sys161 found: $SYS161_BIN"
fi

# ── 3. PATH contains the tools bin directory ──────────────────────────────────
echo ""
log_info "--- Checking PATH ---"

if command -v mips-harvard-os161-gcc > /dev/null 2>&1; then
    found=$(command -v mips-harvard-os161-gcc)
    _pass "mips-harvard-os161-gcc on PATH  ($found)"
else
    _fail "mips-harvard-os161-gcc NOT on PATH — run: export PATH=\$PATH:$TOOLS_DIR/bin"
fi

if command -v sys161 > /dev/null 2>&1; then
    _pass "sys161 on PATH"
else
    _fail "sys161 NOT on PATH"
fi

# ── 4. os161 source tree exists ───────────────────────────────────────────────
echo ""
log_info "--- Checking source tree ---"

SRC="$OS161_DIR/src"
for f in "$SRC/configure" "$SRC/kern/conf/conf.kern" \
          "$SRC/userland/testbin/usemtest/usemtest.c"; do
    if [ -f "$f" ]; then
        _pass "$(basename "$f")  ($f)"
    else
        _fail "Missing: $f"
    fi
done

# ── 5. Cross-compiler can compile a hello-world C file ───────────────────────
echo ""
log_info "--- Compile test ---"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

cat > "$TMPDIR/hello.c" << 'CSRC'
int main(void) { return 0; }
CSRC

if "$TOOLS_DIR/bin/mips-harvard-os161-gcc" \
        -nostdinc -nostdlib \
        -o "$TMPDIR/hello.o" -c "$TMPDIR/hello.c" 2>/dev/null; then
    _pass "Cross-compiled hello.c → hello.o successfully"
    arch=$(file "$TMPDIR/hello.o" 2>/dev/null)
    if echo "$arch" | grep -q "MIPS"; then
        _pass "Output is MIPS object: $arch"
    else
        _fail "Output is NOT MIPS: $arch"
    fi
else
    _fail "Cross-compilation failed"
fi

# ── 6. /etc/profile.d/os161.sh is in place ───────────────────────────────────
echo ""
log_info "--- Checking permanent PATH config ---"

PROFILE="/etc/profile.d/os161.sh"
if [ -f "$PROFILE" ]; then
    _pass "$PROFILE exists"
    if grep -q "$TOOLS_DIR/bin" "$PROFILE"; then
        _pass "$PROFILE contains correct path"
    else
        _fail "$PROFILE does not contain $TOOLS_DIR/bin"
    fi
else
    _fail "$PROFILE missing — run setEnvPermanent.sh"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────"
if [ "$FAIL" -eq 0 ]; then
    log_ok  "All checks passed ($PASS/$((PASS+FAIL)))"
else
    log_error "$FAIL check(s) failed, $PASS passed"
    exit 1
fi

exit 0
