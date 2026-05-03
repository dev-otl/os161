#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
source "$SCRIPT_DIR/common.sh"

mkdir -p "$DOWNLOAD_DIR" "$LOG_DIR"
LOGFILE="$LOG_DIR/download.log"

log_info "Download directory: $DOWNLOAD_DIR"
log_info "Log: $LOGFILE"

TARBALLS=(
    "binutils-2.24+os161-2.1.tar.gz"
    "gcc-4.8.3+os161-2.1.tar.gz"
    "gdb-7.8+os161-2.1.tar.gz"
    "os161-base-2.0.3.tar.gz"
    "sys161-2.0.8.tar.gz"
)

# NOTE: Must use http://, NOT https:// — os161.org does not support TLS.
BASELINK="http://os161.org/download/"

for tarball in "${TARBALLS[@]}"; do
    DEST="$DOWNLOAD_DIR/$tarball"

    if [ -f "$DEST" ]; then
        # Verify the existing file is a complete, readable tarball.
        # tar -tzf does a full table-of-contents pass without extracting.
        # A truncated download will fail this check.
        if tar -tzf "$DEST" > /dev/null 2>&1; then
            log_ok "Already valid: $tarball — skipping"
            continue
        else
            log_warn "Incomplete or corrupt: $tarball — removing and re-downloading"
            rm -f "$DEST"
        fi
    fi

    log_info "Downloading: $tarball"
    wget --progress=bar:force -P "$DOWNLOAD_DIR" "${BASELINK}${tarball}" \
        2>&1 | tee -a "$LOGFILE" || die "wget failed for $tarball"
    log_ok "Downloaded: $tarball"
done

log_ok "All tarballs present in: $DOWNLOAD_DIR"
exit 0
