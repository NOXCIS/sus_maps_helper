#!/bin/sh

# SUS Maps Helper - Boot Script
# Runs at post-fs-data stage, BEFORE susfs4ksu uses the binary.
# 1. Auto-detects unpatched ksu_susfs binary and re-applies the patch.
# 2. Captures the current boot's vbmeta digest for SUSFS VerifiedBootHash.

MODDIR=${0%/*}
DEST_BIN=/data/adb/ksu/bin/ksu_susfs
PATCHED_BIN="${MODDIR}/tools/ksu_susfs_arm64"
SUSFS_CONFIG=/data/adb/susfs4ksu/config.sh
LOGDIR=/data/adb/ksu/susfs4ksu/logs
LOGFILE="${LOGDIR}/sus_maps_helper.log"

# ── Logging ──
mkdir -p "${LOGDIR}" 2>/dev/null
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [sus_maps_helper] $1" >> "${LOGFILE}" 2>/dev/null
}

# Rotate log if over 50KB
if [ -f "${LOGFILE}" ] && [ "$(wc -c < "${LOGFILE}" 2>/dev/null)" -gt 51200 ]; then
    mv -f "${LOGFILE}" "${LOGFILE}.old" 2>/dev/null
    log "Log rotated"
fi

log "Boot detected - checking binary status"

# ── Pre-flight ──
if [ ! -f "${PATCHED_BIN}" ]; then
    log "ERROR: Patched binary missing from module at ${PATCHED_BIN}"
    exit 0
fi

if [ ! -f "${DEST_BIN}" ]; then
    log "ERROR: ${DEST_BIN} does not exist - KernelSU/susfs not installed?"
    exit 0
fi

# ── Auto-detect: is the current binary patched? ──
if "${DEST_BIN}" show enabled_features 2>/dev/null | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
    log "OK: Binary reports CONFIG_KSU_SUSFS_SUS_MAP - already patched"
else
    log "DETECTED: Binary does NOT report CONFIG_KSU_SUSFS_SUS_MAP - unpatched!"
    log "Applying patched binary..."

    # Backup before overwriting
    cp -f "${DEST_BIN}" "${DEST_BIN}.bak.smh" 2>/dev/null

    # Apply the patched binary
    cp -f "${PATCHED_BIN}" "${DEST_BIN}"
    chmod 755 "${DEST_BIN}"
    chown 0:0 "${DEST_BIN}"

    # Verify
    if "${DEST_BIN}" show enabled_features 2>/dev/null | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
        log "SUCCESS: Patched binary applied - SUS_MAP now reported"
    else
        log "WARNING: Binary replaced but SUS_MAP still missing (kernel config issue?)"
    fi
fi

# ── Protect: keep WebUI binary update disabled ──
if [ -f "${SUSFS_CONFIG}" ]; then
    if grep -q "disable_webui_bin_update=0" "${SUSFS_CONFIG}"; then
        sed -i 's/disable_webui_bin_update=0/disable_webui_bin_update=1/' "${SUSFS_CONFIG}"
        log "Re-disabled WebUI binary update (was reset to 0)"
    fi
fi

# ── Capture VerifiedBootHash for SUSFS ──────────────────────────────────
# At post-fs-data time, ro.boot.vbmeta.digest still holds the real digest
# that the bootloader computed for this boot image.  Write it to the file
# that susfs4ksu's service.sh reads via resetprop — no VBMeta Fixer app
# needed, and the hash updates automatically when a new kernel is flashed.
HASH_DIR="/data/adb/VerifiedBootHash"
HASH_FILE="${HASH_DIR}/VerifiedBootHash.txt"

if [ -d "${HASH_DIR}" ]; then
    CURRENT_DIGEST="$(getprop ro.boot.vbmeta.digest)"
    if [ -n "${CURRENT_DIGEST}" ]; then
        STORED_DIGEST=""
        [ -f "${HASH_FILE}" ] && STORED_DIGEST="$(cat "${HASH_FILE}" 2>/dev/null)"
        if [ "${CURRENT_DIGEST}" != "${STORED_DIGEST}" ]; then
            echo -n "${CURRENT_DIGEST}" > "${HASH_FILE}"
            log "VerifiedBootHash updated: ${CURRENT_DIGEST}"
        else
            log "VerifiedBootHash unchanged: ${CURRENT_DIGEST}"
        fi
    else
        log "WARNING: ro.boot.vbmeta.digest is empty — cannot capture hash"
    fi
else
    log "VerifiedBootHash directory missing — skipping (susfs4ksu not configured?)"
fi
