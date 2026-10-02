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
