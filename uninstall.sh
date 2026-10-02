#!/sbin/sh
# FixChinaCarrier (KSU fork) uninstaller.
#
# KSU / Magisk remove the overlay automatically when the module directory
# is deleted, so all we need to do is clean up our own junk files.
# (The original module had $INFO-based manual revert logic; KSU does not
#  use that protocol.)

MODPATH="${MODPATH:-${0%/*}}"

# Nothing to do — system/ overlay disappears with the module dir.
exit 0
