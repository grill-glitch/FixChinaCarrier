#!/sbin/sh
# FixChinaCarrier (KSU fork) — module installer.
#
# Replaces /product/etc/apns-conf.xml (HyperOS location) and
# /system/etc/apns-conf.xml (AOSP fallback) via KernelSU overlayfs /
# Magisk magic mount, using the APN table bundled in $MODPATH/APN/.
#
# KSU docs: https://kernelsu.org/zh_CN/guide/module.html
#   - system/ contents are overlaid by KSU via overlayfs
#   - Magisk still uses bind mount (magic mount), but the same layout works
#   - id in module.prop must match ^[a-zA-Z][a-zA-Z0-9._-]+$
#
# Root framework detection (KSU vs Magisk):
#   - KernelSU sets KSU=true (see "Shell 脚本" section of the KSU module guide).
#   - Magisk does NOT set KSU; its util_functions.sh is not loaded here.

set -e

# Prefer MODPATH from env (KSU/Magisk export it before sourcing this script).
# Fall back to ${0%/*} for direct invocation.
MODPATH="${MODPATH:-${0%/*}}"
APN_SRC="$MODPATH/APN/apns-conf.xml"

# Sanity: ensure apn source exists.
if [ ! -f "$APN_SRC" ]; then
  echo "! APN/apns-conf.xml missing in module" >&2
  exit 1
fi

ui_print() { echo "$1"; }

# Detect root framework. We DO NOT source Magisk util_functions.sh because
# KernelSU does not ship it; sourcing it would break KSU installs.
if [ "$KSU" = "true" ]; then
  ui_print "  Root: KernelSU"
  ROOT="KSU"
elif [ -n "$MAGISK_VER_CODE" ]; then
  ui_print "  Root: Magisk"
  ROOT="MAGISK"
else
  ui_print "! Neither KSU nor Magisk detected. Aborting."
  exit 1
fi

# Decide which /system paths to overlay with our apns-conf.xml.
#
# HyperOS (recent Xiaomi ROMs): apns-conf.xml lives in /product/etc/.
# AOSP (legacy): /system/etc/.
# Some ROMs vendor it under /vendor/etc/ or /system/system_ext/etc/.
# We overlay every path that exists on the running system, so one zip
# works on HyperOS, crDroid, LineageOS, AOSP, etc.

TARGETS="system/etc product/etc vendor/etc system/system_ext/etc"
INSTALLED=0

for REL in $TARGETS; do
  ABS="/$REL"
  if [ -d "$ABS" ]; then
    DEST="$MODPATH/$REL"
    mkdir -p "$DEST"
    # Honor REMOVE / REPLACE variables from KSU guide:
    #   REMOVE: list of paths to whiteout (kernel mknod c 0 0 done by KSU)
    #   REPLACE: list of dirs to setfattr trusted.overlay.opaque=y (done by KSU)
    # We do NOT set them here because we ADD a file, not remove/replace a dir.
    cp -f "$APN_SRC" "$DEST/apns-conf.xml"
    ui_print "  Installed: $REL/apns-conf.xml"
    INSTALLED=$((INSTALLED + 1))
  fi
done

if [ "$INSTALLED" -eq 0 ]; then
  ui_print "! No known APN target directory found on this ROM."
  ui_print "  Tried: $TARGETS"
  exit 1
fi

ui_print "  Done — overlaid $INSTALLED path(s) on $ROOT"
