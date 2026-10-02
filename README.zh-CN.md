# FixChinaCarrier (KSU 分支)

[English](README.md) | [简体中文](README.zh-CN.md)

[![Upstream](https://img.shields.io/badge/upstream-RiwiHow%2FFixChinaCarrier-blue)](https://github.com/RiwiHow/FixChinaCarrier)
[![Fork](https://img.shields.io/badge/fork-grill--glitch%2FFixChinaCarrier-green)](https://github.com/grill-glitch/FixChinaCarrier)

> 本仓库（`grill-glitch/FixChinaCarrier`）的主分支是 `ksu`。
> 原始项目：[RiwiHow/FixChinaCarrier](https://github.com/RiwiHow/FixChinaCarrier)

**本 fork** 移除了 MMT Extended Magisk 模块模板（该模板在 KernelSU 下会硬性失败，
因为它依赖 `/data/adb/magisk/util_functions.sh`），改用一个极简的 KSU/Magisk 双兼容安装器，
按 [KernelSU 模块开发指南](https://kernelsu.org/zh_CN/guide/module.html) 通过 `$KSU` 环境变量
识别宿主。

APN 表来自 **HyperOS OS3.0.306.0.WNCCNXM**（小米 14 Ultra / 内部代号 `houji`）工厂刷机包内
的 `product/etc/apns-conf.xml`，共 **4734** 条 `<apn>`，比上游 v5.3.2 的 4466 条多 268 条
（覆盖更多国内外运营商，包括中国电信 460/04 `dcnet`、中国广电 460/15 xcap、联通 IMS 等
HyperOS 新增条目）。

## 功能特性

- 修复中国移动 / 联通 / 电信 / 广电等中国运营商 APN 慢速问题。
- 同时支持 **KernelSU 与 Magisk**。
- Systemless 替换：KSU 用 overlayfs，Magisk 用 magic mount。
- 自动把 `apns-conf.xml` 写入运行 ROM 上所有已知路径
  （`/product/etc`、`/system/etc`、`/vendor/etc`、`/system/system_ext/etc`），
  同一个 zip 即可在 HyperOS、crDroid、LineageOS、AOSP 上工作。

## 与上游 v5.3.2 的差异

| 文件 | 改动 |
|---|---|
| `module.prop` | 新 id `fixchinacarrier-ksu`，版本 v6.0.3（20261002） |
| `META-INF/.../update-binary` | 恢复为标准 Magisk 入口（`. util_functions.sh` + `install_module()`）；**KSU 从不读取此文件** |
| `customize.sh` | 完全重写：去掉 MMT Extended、去掉 `unzip + . common/functions.sh`、**不加 `set -e`**，只做显式 overlay 拷贝 |
| `uninstall.sh` | 完全重写：KSU/Magisk 模块卸载时自动清理 overlay |
| `common/` | **整目录删除**（MMT Extended 模板，依赖 KSU 不提供的 Magisk 内部机制） |
| `system/placeholder` | 删除 |
| `APN/apns-conf.xml` | 替换为 HyperOS OS3.0.306.0.WNCCNXM `product/etc/apns-conf.xml`（4734 条） |
| `README.md` | 完整英文文档 |
| `README.zh-CN.md` | 完整简体中文文档（本 fork） |

## 工作原理

```
APN/apns-conf.xml  ──copy──>  $MODPATH/product/etc/apns-conf.xml   (HyperOS 默认位置)
                            $MODPATH/system/etc/apns-conf.xml    (AOSP 默认位置)
                            $MODPATH/vendor/etc/apns-conf.xml    (部分 vendor ROM)
                            $MODPATH/system/system_ext/etc/apns-conf.xml (system_ext)
                            │
                            └─ KSU overlayfs / Magisk magic mount ──> 实际生效的 /product/etc/apns-conf.xml
```

## 安装要求

- Android 8 及以上（模块只覆盖 `apns-conf.xml`）。
- **KernelSU**（任意近期版本）**或** **Magisk 20.4+**。
- 你的 ROM 至少在以下路径之一有 `apns-conf.xml`：
  `/product/etc`、`/system/etc`、`/vendor/etc`、`/system/system_ext/etc`。

## 安装步骤

1. 从 [Releases](../../releases) 下载 `fixchinacarrier-ksu-v6.0.3.zip`。
2. **KernelSU Manager → 模块 → 从本地安装**，或 **Magisk Manager → 模块 → 从本地安装**。
3. 重启。
4. 设置 → 移动网络 → 接入点名称 (APN) → **重置为默认**。

## KSU 兼容性——真正需要改的地方

**KernelSU 根本不执行 zip 里的 `META-INF/com/google/android/update-binary`。**
这一点已在 ksud 源码中核实（`KernelSU-Next/userspace/ksud/src/module.rs` →
`exec_install_script` → `metamodule::get_install_script`）：KSU 执行的安装脚本
只可能是它内置的 `installer.sh`（`INSTALLER_CONTENT`），或是当前 metamodule
的 `metainstall.sh`。所以决定模块能否在 KSU 装上的是 **`customize.sh`** ——
KSU 把 zip 解压到 `$MODPATH` 后直接 source 它。

上游的 `customize.sh` 是：

```sh
DEBUG=true
SKIPUNZIP=1
unzip -qjo "$ZIPFILE" 'common/functions.sh' -d $TMPDIR >&2
. $TMPDIR/functions.sh
```

也就是说它把一切都交给 Zackptg5 的 **MMT Extended** 模板，而该模板是照着
Magisk 内部机制写的（`$VKSEL`、`$NVBASE`、`$MAGISKTMP`、`$API`、
`install_script`、MMT 自带的 `set_permissions`、`Volume-Key-Selector`
音量键二进制……）。这些在 KSU 的 `installer.sh` 下要么不存在、要么行为不同。
本 fork 把 `customize.sh` 改成自包含的 POSIX `sh`，只使用两个宿主都保证提供的
机制，并整体删除 `common/` 目录。

因此 `META-INF/.../update-binary` **保留为 Magisk 的入口**，做标准 Magisk 流程
（`. /data/adb/magisk/util_functions.sh` + `install_module()`），让 Magisk 安装
照常工作。

`Volume-Key-Selector` 音量键 addon 也一并删除了：KSU 的安装是在运行中的
Android 界面里完成的，没有音量键选择交互可答。

### ⚠️ 绝对不要在 `customize.sh` 里用 `set -e`

`customize.sh` 是被 **source** 执行的，不是独立运行 —— KSU 的
`ksud/src/installer.sh` 在 `install_module()` 里执行 `. $MODPATH/customize.sh`。
因此模块设置的任何 shell 选项都会**泄漏到宿主安装脚本**，并在模块脚本返回后
继续生效。之前加了 `set -e`，导致安装最后报：

```
- Error: Failed to install module script
```

而此时模块其实已经正确解压并完成 overlay 了。原因是宿主在模块脚本返回后还要
继续自己的收尾工作，KSU-Next `installer.sh` 第 458 行是：

```sh
rmdir -p $MODPATH 2>/dev/null      # 模块目录非空，返回 1
```

被泄漏的 `errexit` 会把这一个非零返回当成致命错误，直接中止整个安装 shell。
v6.0.3 的修复方式是**完全不碰 shell 选项**，改为显式检查错误，真正装不了时
通过宿主的 `abort()` 失败。

## 故障排查

#### 提示 "Neither KSU nor Magisk detected"

没有支持的 root 框架。请先装 KernelSU 或 Magisk。

#### 提示 "No known APN target directory found"

你的 ROM 在 `/product/etc`、`/system/etc`、`/vendor/etc`、`/system/system_ext/etc`
都没有 `apns-conf.xml`。请开 issue 并附上 root shell 里
`find / -name apns-conf.xml 2>/dev/null` 的输出。

#### 模块装上了，但 APN 列表还是旧的

部分运营商按 SIM 卡缓存 APN 列表。重启后请：
设置 → 移动网络 → 接入点名称 (APN) → 右上角菜单 (⋮) → **重置为默认**。

#### HyperOS 上还看到旧的 APN

HyperOS 的「双卡与移动网络 → 接入点名称」每次进入都会读一次 `/product/etc/apns-conf.xml`。
如果 overlay 没生效，先确认 KernelSU 模块列表里 fixchinacarrier-ksu 是启用状态，
再看 `/data/adb/modules/fixchinacarrier-ksu/product/etc/apns-conf.xml` 是否存在，
最后用 `mount | grep overlay` 检查 overlayfs 是否真的挂上了。

## 致谢

- [RiwiHow](https://github.com/RiwiHow) / Qingxu — 原模块与 APN 上游工作。
- [Magisk](https://github.com/topjohnwu/Magisk) — 原始工具链。
- [Zackptg5](https://forum.xda-developers.com/m/zackptg5.6037748/) — MMT Extended 模板
  （本 fork 已不再使用，但原上游基于该模板构建）。
- [grill-glitch](https://github.com/grill-glitch) — KSU 移植与 HyperOS APN 刷新。

## 许可

Apache-2.0（见 [LICENSE](LICENSE)）。继承上游许可。
