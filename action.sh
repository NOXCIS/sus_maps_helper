#!/bin/sh

# SUS Maps Helper - Action Button (Manual Patch)
# Triggered from KernelSU Next app -> Modules -> SUS Maps Helper -> Execute

MODDIR=${0%/*}
DEST_BIN=/data/adb/ksu/bin/ksu_susfs
PATCHED_BIN="${MODDIR}/tools/ksu_susfs_arm64"
SUSFS_CONFIG=/data/adb/susfs4ksu/config.sh

echo "============================================"
echo "  SUS Maps Helper - Manual Patch"
echo "============================================"
echo ""

# ── Pre-flight checks ──
if [ ! -f "${PATCHED_BIN}" ]; then
    echo "[!] ERROR: Patched binary not found in module!"
    echo "    Expected: ${PATCHED_BIN}"
    echo ""
    echo "    Reinstall the SUS Maps Helper module."
    exit 1
fi

if [ ! -f "${DEST_BIN}" ]; then
    echo "[!] ERROR: ksu_susfs binary not found!"
    echo "    Expected: ${DEST_BIN}"
    echo ""
    echo "    Install KernelSU and susfs4ksu module first."
    exit 1
fi

# ── Check current binary status ──
echo "[*] Checking current binary..."
echo ""

current_features=$("${DEST_BIN}" show enabled_features 2>/dev/null)
current_version=$("${DEST_BIN}" show version 2>/dev/null)

echo "    SUSFS Version : ${current_version:-unknown}"
echo ""

if echo "${current_features}" | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
    echo "    SUS_MAP Status: ENABLED"
    echo ""
    echo "[+] Binary is already patched - no action needed."
    echo ""
    echo "── Current Enabled Features ──"
    echo "${current_features}" | sed 's/^/    /'
else
    echo "    SUS_MAP Status: DISABLED (unpatched binary detected)"
    echo ""
    echo "[*] Applying patched binary..."

    # Backup current binary
    cp -f "${DEST_BIN}" "${DEST_BIN}.bak" 2>/dev/null

    # Apply patch
    cp -f "${PATCHED_BIN}" "${DEST_BIN}"
    chmod 755 "${DEST_BIN}"
    chown 0:0 "${DEST_BIN}"

    # Verify
    new_features=$("${DEST_BIN}" show enabled_features 2>/dev/null)

    if echo "${new_features}" | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
        echo "[+] SUCCESS: Binary patched!"
        echo "    SUS_MAP Status: ENABLED"
        echo ""
        echo "    Refresh the SUSFS status page to see the change."
    else
        echo "[!] WARNING: Binary replaced but SUS_MAP still not reported."
        echo "    Your kernel may not have CONFIG_KSU_SUSFS_SUS_MAP enabled."
        echo "    Rebuild kernel with CONFIG_KSU_SUSFS_SUS_MAP=y in defconfig."
    fi

    echo ""
    echo "── Updated Enabled Features ──"
    echo "${new_features}" | sed 's/^/    /'
fi

# ── Ensure WebUI binary update is disabled ──
echo ""
if [ -f "${SUSFS_CONFIG}" ]; then
    if grep -q "disable_webui_bin_update=0" "${SUSFS_CONFIG}"; then
        sed -i 's/disable_webui_bin_update=0/disable_webui_bin_update=1/' "${SUSFS_CONFIG}"
        echo "[*] WebUI binary update was enabled - disabled it to protect patch."
    elif grep -q "disable_webui_bin_update=1" "${SUSFS_CONFIG}"; then
        echo "[+] WebUI binary update: disabled (protected)"
    else
        echo "disable_webui_bin_update=1" >> "${SUSFS_CONFIG}"
        echo "[*] Added WebUI binary update protection to config."
    fi
else
    echo "[!] susfs4ksu config not found - is the susfs4ksu module installed?"
fi

echo ""
echo "============================================"
echo "  Done"
echo "============================================"
