#!/bin/bash
# common.sh — sourced by every other script. Do not execute directly.
#
# Assumes SCRIPT_DIR has already been set by the caller to the directory
# containing the scripts (i.e. the repo root).  Each script sets this with:
#   SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# ── Configurable paths ────────────────────────────────────────────────────────
# Override any of these via environment variables before running a script.
DOWNLOAD_DIR="${DOWNLOAD_DIR:-$SCRIPT_DIR/downloads}"
OS161_DIR="${OS161_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)/os161}"
TOOLBUILD_DIR="$OS161_DIR/toolbuild"
TOOLS_DIR="$OS161_DIR/tools"
LOG_DIR="${LOG_DIR:-$SCRIPT_DIR/logs}"
# ─────────────────────────────────────────────────────────────────────────────

# ── Parallelism ───────────────────────────────────────────────────────────────
# How many CPU threads each make invocation may use.
# When multiple components build in parallel (see setupOS161.sh), each one gets
# this many threads — so total load = MAKE_JOBS * number_of_parallel_components.
# Default: all cores / 2, minimum 1.  Override: MAKE_JOBS=4 ./install.sh
_ncpu=$(nproc 2>/dev/null || echo 2)
MAKE_JOBS="${MAKE_JOBS:-$(( _ncpu > 1 ? _ncpu / 2 : 1 ))}"
MAKE_FLAGS="-j${MAKE_JOBS} -s"
# ─────────────────────────────────────────────────────────────────────────────

# ── Colours (disabled automatically when stdout is not a TTY) ─────────────────
if [ -t 1 ]; then
    _RED='\033[0;31m'; _YELLOW='\033[1;33m'; _GREEN='\033[0;32m'
    _CYAN='\033[0;36m'; _BOLD='\033[1m'; _NC='\033[0m'
else
    _RED=''; _YELLOW=''; _GREEN=''; _CYAN=''; _BOLD=''; _NC=''
fi

# ── Logging ───────────────────────────────────────────────────────────────────
log_info()  { printf "${_CYAN}[INFO]${_NC}  %s\n" "$*"; }
log_ok()    { printf "${_GREEN}[OK]${_NC}    %s\n" "$*"; }
log_warn()  { printf "${_YELLOW}[WARN]${_NC}  %s\n" "$*"; }
log_error() { printf "${_RED}[ERROR]${_NC} %s\n" "$*" >&2; }

die() { log_error "$*"; exit 1; }

# ── Tarball lookup ────────────────────────────────────────────────────────────
# find_tarball GLOB
# Prints the path to the matching tarball in DOWNLOAD_DIR, or dies with a
# clear message if it is not there (rather than a cryptic tar error).
find_tarball() {
    local pattern="$1"
    local result
    result=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name "$pattern" -print -quit 2>/dev/null)
    if [ -z "$result" ]; then
        die "Tarball '$pattern' not found in $DOWNLOAD_DIR — run downloadTarballs.sh first"
    fi
    printf '%s' "$result"
}

# ── Step runner ───────────────────────────────────────────────────────────────
# run_step NAME LOGFILE FUNCNAME
#   Runs FUNCNAME in a subshell (so cd/set changes stay contained), appending
#   all output to LOGFILE.  Prints a one-line summary on the terminal.
#   On failure: prints the last 30 log lines and exits with the failed exit code.
run_step() {
    local name="$1" logfile="$2" fn="$3"
    mkdir -p "$(dirname "$logfile")"
    log_info "Starting:  ${_BOLD}${name}${_NC}"
    if ( set -euo pipefail; "$fn" ) > "$logfile" 2>&1; then
        log_ok "Finished:  ${_BOLD}${name}${_NC}"
    else
        local rc=$?
        log_error "FAILED:    ${_BOLD}${name}${_NC}  (exit $rc)"
        log_error "Last 30 lines of ${_BOLD}${logfile}${_NC}:"
        tail -n 30 "$logfile" >&2
        exit "$rc"
    fi
}

# run_step_bg NAME LOGFILE FUNCNAME
#   Same as run_step but backgrounds the job.  After calling this, $! is the
#   PID of the background job.  Collect results with wait_step.
run_step_bg() {
    local name="$1" logfile="$2" fn="$3"
    mkdir -p "$(dirname "$logfile")"
    log_info "Spawning:  ${_BOLD}${name}${_NC}  → ${logfile}"
    ( set -euo pipefail; "$fn" ) > "$logfile" 2>&1 &
    # $! in the caller will be the PID of the subshell just backgrounded.
}

# wait_step NAME PID LOGFILE
#   Waits for a background job and reports the result.  Does NOT exit on
#   failure — sets PARALLEL_FAILED=1 instead so callers can collect all
#   failures before deciding to abort.
wait_step() {
    local name="$1" pid="$2" logfile="$3"
    if wait "$pid"; then
        log_ok "Finished:  ${_BOLD}${name}${_NC}"
    else
        local rc=$?
        log_error "FAILED:    ${_BOLD}${name}${_NC}  (exit $rc)"
        log_error "Last 30 lines of ${_BOLD}${logfile}${_NC}:"
        tail -n 30 "$logfile" >&2
        PARALLEL_FAILED=1
    fi
}
