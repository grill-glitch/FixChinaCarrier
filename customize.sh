#!/sbin/sh
# FixChinaCarrier (KSU fork) - module customization.
#
# Overlays apns-conf.xml into every APN config path that exists on the running
# ROM, using the table bundled in $MODPATH/APN/apns-conf.xml.
#
# KSU docs: https://kernelsu.org/zh_CN/guide/module.html
#   - system/ contents are overlaid by KSU via overlayfs
#   - Magisk still uses bind mount (magic mount); the same layout works
#   - id in module.prop must match ^[a-zA-Z][a-zA-Z0-9._-]+$
#
# Root framework detection:
#   - KernelSU sets KSU=true (see "Shell 脚本" section of the KSU module guide)
#   - Magisk sets MAGISK_VER_CODE and does NOT set KSU
#
# !!! IMPORTANT - DO NOT USE `set -e` IN THIS FILE !!!
#
# This script is SOURCED (`. $MODPATH/customize.sh`) by the host installer:
#   KernelSU : userspace/ksud/src/installer.sh  -> install_module()
#   Magisk   : util_functions.sh                -> install_module()
#
# A `set -e` here LEAKS into the host's shell and stays active after we return.
# The host then continues with its own housekeeping, e.g. KSU-Next
# installer.sh line 458:
#
#     rmdir -p $MODPATH 2>/dev/null     # returns 1: module dir is not empty
#
# Under the leaked errexit that single non-zero return kills the whole
# installer shell, and the manager reports:
#
#     - Error: Failed to install module script
#
# even though the module was extracted and overlaid correctly. So: check
# errors explicitly (see the cp below) and fail via abort(), never with `set -e`.

# --- resolve our own module directory -------------------------------------
# The host sets MODPATH before sourcing us; fall back to a sane default for
# manual/diagnostic runs.
if [ -z "$MODPATH" ]; then
  case "$0" in
  */*) MODPATH="${0%/*}" ;;
  *) MODPATH="/data/adb/modules/${MODID:-fixchinacarrier-ksu}" ;;
  esac
fi

APN_SRC="$MODPATH/APN/apns-conf.xml"

# ui_print is provided by the host; define a fallback for manual runs.
type ui_print >/dev/null 2>&1 || ui_print() { echo "$1"; }

# Fail the install so the manager shows a real error instead of a silent
# half-install. Prefer the host's abort() (KSU installer.sh / Magisk
# util_functions.sh both define one).
die() {
  ui_print "! $1"
  type abort >/dev/null 2>&1 && abort "$1"
  exit 1
}

[ -f "$APN_SRC" ] || die "APN/apns-conf.xml missing in module ($APN_SRC)"

# --- detect root framework ------------------------------------------------
if [ "$KSU" = "true" ]; then
  ui_print "  Root: KernelSU"
  ROOT="KSU"
elif [ -n "$MAGISK_VER_CODE" ]; then
  ui_print "  Root: Magisk"
  ROOT="MAGISK"
else
  die "Neither KSU nor Magisk detected."
fi

# --- pick overlay targets -------------------------------------------------
# HyperOS (recent Xiaomi ROMs) keeps it in /product/etc.
# AOSP/legacy keeps it in /system/etc.
# Some ROMs also ship one under /vendor/etc or /system/system_ext/etc.
# Overlay every path that exists, so one zip works everywhere.
#
# NOTE: do NOT set REMOVE / REPLACE here. We only ADD a file; KSU's overlayfs
# whiteout (mknod c 0 0) and opaque-dir (setfattr trusted.overlay.opaque)
# machinery is for deleting/replacing existing paths, which we do not do.
TARGETS="system/etc product/etc vendor/etc system/system_ext/etc"
INSTALLED=0

for REL in $TARGETS; do
  ABS="/$REL"
  [ -d "$ABS" ] || continue
  DEST="$MODPATH/$REL"
  mkdir -p "$DEST" || die "cannot create $DEST"
  if cp -f "$APN_SRC" "$DEST/apns-conf.xml"; then
    ui_print "  Installed: $REL/apns-conf.xml"
    INSTALLED=$((INSTALLED + 1))
  else
    die "failed to copy apns-conf.xml to $REL"
  fi
done

[ "$INSTALLED" -gt 0 ] ||
  die "No known APN target directory found on this ROM. Tried: $TARGETS"

ui_print "  Done - overlaid $INSTALLED path(s) on $ROOT"
