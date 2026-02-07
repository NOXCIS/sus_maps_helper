# SUS Maps Helper - Mi Mix 4

> **WARNING: This module is built exclusively for the Xiaomi Mi Mix 4 (codename: `odin`). The included binary is compiled for this device's specific kernel configuration. Do NOT install this on any other device - it will not work and may cause issues.**

A KernelSU Next module that maintains a patched `ksu_susfs` binary with **SUS_MAP (bit 15)** support for SUSFS v1.5.5 on non-GKI kernels.

## Problem

The stock `ksu_susfs` binary shipped with the [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) for SUSFS v1.5.5 only decodes feature bits 0-14. SUS_MAP support (bit 15) was added in SUSFS v1.5.12+, but the kernel can have it backported while still reporting v1.5.5. The module's binary update mechanism downloads the binary matching the kernel's reported version, which overwrites any patched binary.

## Solution

This module:
- **On install**: Replaces `/data/adb/ksu/bin/ksu_susfs` with a patched binary that decodes bit 15 (SUS_MAP)
- **On every boot**: Checks if the binary still reports `CONFIG_KSU_SUSFS_SUS_MAP` and re-applies the patch if the susfs4ksu module overwrote it
- **Prevents overwrites**: Sets `disable_webui_bin_update=1` in the susfs4ksu config

## Requirements

- Xiaomi Mi Mix 4 (odin) with kernel 5.4.x
- KernelSU Next with SUSFS v1.5.5 and `CONFIG_KSU_SUSFS_SUS_MAP=y` in defconfig
- [susfs4ksu-module](https://github.com/sidex15/susfs4ksu-module) R19+

## Installation

1. Download `SUS_Maps_Helper.zip` from [Releases](../../releases)
2. Open KernelSU Next app
3. Go to Modules -> Install from storage
4. Select the zip and reboot

Or via ADB:
```bash
adb push SUS_Maps_Helper.zip /data/local/tmp/
adb shell "su -c '/data/adb/ksu/bin/ksud module install /data/local/tmp/SUS_Maps_Helper.zip'"
adb shell "rm /data/local/tmp/SUS_Maps_Helper.zip"
# Reboot to activate
adb reboot
```

## Logs

The module logs its actions to:
```
/data/adb/ksu/susfs4ksu/logs/sus_maps_helper.log
```

## How It Works

The SUSFS kernel reports enabled features as a bitmask via `CMD_SUSFS_SHOW_ENABLED_FEATURES`. The `ksu_susfs` userspace binary decodes this bitmask into config strings that the susfs4ksu module's WebUI reads to display feature status.

| Bit | Feature | Stock v1.5.5 Binary | Patched Binary |
|-----|---------|---------------------|----------------|
| 0-14 | Various SUSFS features | Decoded | Decoded |
| 15 | `CONFIG_KSU_SUSFS_SUS_MAP` | **Not decoded** | **Decoded** |

Without this module, the WebUI shows "SUS Maps Support: Disabled" even when the kernel has it enabled, because the binary can't translate bit 15 into the expected config string.

## Credits

- [simonpunk](https://gitlab.com/simonpunk/susfs4ksu/) - SUSFS
- [sidex15](https://github.com/sidex15/susfs4ksu-module) - susfs4ksu module
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) - KernelSU Next

## License

GPL-3.0
