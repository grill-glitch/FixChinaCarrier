# FixChinaCarrier (KSU fork)

[English](README.md) | [简体中文](README.zh-CN.md)

[![Upstream](https://img.shields.io/badge/upstream-RiwiHow%2FFixChinaCarrier-blue)](https://github.com/RiwiHow/FixChinaCarrier)
[![Fork](https://img.shields.io/badge/fork-grill--glitch%2FFixChinaCarrier-green)](https://github.com/grill-glitch/FixChinaCarrier)

KernelSU-compatible fork of [RiwiHow/FixChinaCarrier](https://github.com/RiwiHow/FixChinaCarrier).

**This fork** drops the MMT Extended Magisk template (which hard-fails on KernelSU
because it requires `/data/adb/magisk/util_functions.sh`) and replaces it with a
minimal KSU/Magisk dual-path installer that uses `$KSU` to detect the host (per
the [KernelSU module guide](https://kernelsu.org/zh_CN/guide/module.html)).

It also bundles the `apns-conf.xml` extracted from a HyperOS
**OS3.0.306.0.WNCCNXM** factory image (Xiaomi 14 Ultra / `houji`) — 4734 entries
vs the upstream 4466.

## Features

- Fixes slow APN on Chinese carriers (CMCC / CUCC / CTCC / CBN).
- Works on **both KernelSU and Magisk**.
- Systemless via overlayfs (KSU) / magic mount (Magisk).
- Overlays `apns-conf.xml` into every known path on the running ROM
  (`/product/etc`, `/system/etc`, `/vendor/etc`, `/system/system_ext/etc`),
  so the same zip works on HyperOS, crDroid, LineageOS, AOSP.

## Changes vs upstream v5.3.2

| File | Change |
|---|---|
| `module.prop` | new id `fixchinacarrier-ksu`, version v6.0.3 (20261002) |
| `META-INF/.../update-binary` | restored to a plain Magisk entry point (`. util_functions.sh` + `install_module()`); **KSU never reads this file** |
| `customize.sh` | rewritten: no MMT Extended, no `unzip + . common/functions.sh`, no `set -e`; just explicit overlay copies |
| `uninstall.sh` | rewritten: KSU/Magisk clean the overlay automatically |
| `common/` | **deleted** (was MMT Extended; needs Magisk-only internals KSU doesn't provide) |
| `system/placeholder` | deleted |
| `APN/apns-conf.xml` | replaced with HyperOS OS3.0.306.0.WNCCNXM `product/etc/apns-conf.xml` (4734 entries) |
| `README.md` | full English documentation |
| `README.zh-CN.md` | full 简体中文 documentation (this fork) |

## How it works

```
APN/apns-conf.xml  ──copy──>  $MODPATH/product/etc/apns-conf.xml   (HyperOS)
                            $MODPATH/system/etc/apns-conf.xml    (AOSP)
                            $MODPATH/vendor/etc/apns-conf.xml    (vendor ROMs)
                            $MODPATH/system/system_ext/etc/apns-conf.xml (system_ext)
                            │
                            └─ KSU overlayfs / Magisk magic mount ──> /product/etc/apns-conf.xml (effective)
```

## Requirements

- Android 8+ (the module only overlays `apns-conf.xml`).
- **KernelSU** (any recent version) **OR** **Magisk 20.4+**.
- A ROM that ships `apns-conf.xml` in at least one of:
  `/product/etc`, `/system/etc`, `/vendor/etc`, `/system/system_ext/etc`.

## Install

1. Download `fixchinacarrier-ksu-v6.0.3.zip` from [Releases](../../releases).
2. Install via KernelSU Manager → Modules → Install from storage, **or**
   via Magisk Manager → Modules → Install from storage.
3. Reboot.
4. Settings → Mobile network → Access Point Names → **Reset to default**.

## Troubleshooting

#### "Neither KSU nor Magisk detected"

You're not running a supported root framework. Install KernelSU or Magisk first.

#### "No known APN target directory found"

Your ROM doesn't ship `apns-conf.xml` in any of `/product/etc`,
`/system/etc`, `/vendor/etc`, or `/system/system_ext/etc`. Open an issue
with the output of `find / -name apns-conf.xml 2>/dev/null` from a root shell.

#### Module installs but APN settings still show the old list

Some carriers cache the APN list per-SIM. After reboot:
Settings → Mobile network → APN → menu (⋮) → **Reset to default**.

## Credits

- [RiwiHow](https://github.com/RiwiHow) / Qingxu — original module & upstream APN work.
- [Magisk](https://github.com/topjohnwu/Magisk) for the original toolchain.
- [Zackptg5](https://forum.xda-developers.com/m/zackptg5.6037748/) for the MMT Extended template (no longer used by this fork, but the original upstream was based on it).
- [grill-glitch](https://github.com/grill-glitch) — KSU port & HyperOS APN refresh.

## License

Apache-2.0 (see [LICENSE](LICENSE)). Upstream-licensed.
