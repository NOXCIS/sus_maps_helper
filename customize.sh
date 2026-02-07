#!/bin/sh

# SUS Maps Helper - Installation Script
# Ensures the patched ksu_susfs binary with SUS_MAP bit 15 decoding
# is installed and protected from being overwritten.

DEST_BIN=/data/adb/ksu/bin/ksu_susfs
SUSFS_CONFIG=/data/adb/susfs4ksu/config.sh

if [ -z "$KSU" ]; then
    abort '[!] This module is for KernelSU only.'
fi

if [ ! -d /data/adb/ksu/bin ]; then
    abort '[!] /data/adb/ksu/bin not found. Install KernelSU first.'
fi

ui_print ""
ui_print "========================================="
ui_print "  SUS Maps Helper - Mi Mix 4"
ui_print "========================================="
ui_print ""

# Install the patched binary
ui_print "[-] Installing patched ksu_susfs binary..."
cp -f "${MODPATH}/tools/ksu_susfs_arm64" "${DEST_BIN}"
chmod 755 "${DEST_BIN}"
chown 0:0 "${DEST_BIN}"

# Verify installation
if "${DEST_BIN}" show enabled_features 2>/dev/null | grep -q "CONFIG_KSU_SUSFS_SUS_MAP"; then
    ui_print "[+] SUS_MAP support verified in binary!"
else
    ui_print "[!] Warning: Could not verify SUS_MAP in binary output."
    ui_print "[!] The kernel may not have CONFIG_KSU_SUSFS_SUS_MAP enabled."
fi

# Disable susfs4ksu WebUI binary updates to prevent overwriting
if [ -f "${SUSFS_CONFIG}" ]; then
    if grep -q "disable_webui_bin_update=" "${SUSFS_CONFIG}"; then
        sed -i 's/disable_webui_bin_update=.*/disable_webui_bin_update=1/' "${SUSFS_CONFIG}"
    else
        echo "disable_webui_bin_update=1" >> "${SUSFS_CONFIG}"
    fi
    ui_print "[-] Disabled susfs4ksu WebUI binary updates"
fi

ui_print ""
ui_print "[+] Installation complete!"
ui_print "[+] The patched binary will be re-applied on every boot."
ui_print ""

# Clean up module directory - we don't need overlay files
rm -f "${MODPATH}/customize.sh"
