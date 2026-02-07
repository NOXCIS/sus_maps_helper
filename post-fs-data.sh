#!/bin/sh

# SUS Maps Helper - Boot Script
# Re-applies the patched ksu_susfs binary on every boot.
# This runs BEFORE susfs4ksu's post-fs-data.sh uses the binary,
# ensuring SUS_MAP (bit 15) is always correctly reported.

MODDIR=${0%/*}
DEST_BIN=/data/adb/ksu/bin/ksu_susfs
PATCHED_BIN="${MODDIR}/tools/ksu_susfs_arm64"
SUSFS_CONFIG=/data/adb/susfs4ksu/config.sh
LOGFILE=/data/adb/ksu/susfs4ksu/logs/sus_maps_helper.log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') sus_maps_helper: $1" >> "${LOGFILE}" 2>/dev/null
}

# Only act if the patched binary exists in our module
if [ ! -f "${PATCHED_BIN}" ]; then
    log "ERROR: Patched binary not found at ${PATCHED_BIN}"
    exit 0
fi

# Check if current binary already has SUS_MAP support
if "${DEST_BIN}" show enabled_features 2>/dev/null | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
    log "Binary already reports SUS_MAP - no action needed"
else
    # Binary was overwritten (module reinstall/update) - re-apply
    log "SUS_MAP missing from binary output - re-applying patched binary"
    cp -f "${PATCHED_BIN}" "${DEST_BIN}"
    chmod 755 "${DEST_BIN}"
    chown 0:0 "${DEST_BIN}"

    if "${DEST_BIN}" show enabled_features 2>/dev/null | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
        log "SUCCESS: Patched binary re-applied, SUS_MAP now reported"
    else
        log "WARNING: Binary replaced but SUS_MAP still not in output (kernel config issue?)"
    fi
fi

# Ensure WebUI binary update stays disabled
if [ -f "${SUSFS_CONFIG}" ]; then
    if grep -q "disable_webui_bin_update=0" "${SUSFS_CONFIG}"; then
        sed -i 's/disable_webui_bin_update=0/disable_webui_bin_update=1/' "${SUSFS_CONFIG}"
        log "Re-disabled WebUI binary update"
    fi
fi
