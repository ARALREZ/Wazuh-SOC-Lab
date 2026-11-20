#!/usr/bin/env bash
set -euo pipefail
TARGET_USER="p04-labuser"
ADMIN_USER="aralrez"

if [[ "$EUID" -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi
password_state() { passwd -S "$1" | awk '{print $2}'; }

id "$TARGET_USER" >/dev/null 2>&1 || { echo "ERROR: $TARGET_USER does not exist; refusing cleanup." >&2; exit 1; }
id "$ADMIN_USER" >/dev/null 2>&1 || { echo "ERROR: $ADMIN_USER does not exist; refusing cleanup." >&2; exit 1; }

ADMIN_BEFORE="$(password_state "$ADMIN_USER")"
[[ "$ADMIN_BEFORE" == "P" ]] || {
  echo "ERROR: $ADMIN_USER must be P (observed $ADMIN_BEFORE); no account changed." >&2
  exit 1
}

TARGET_BEFORE="$(password_state "$TARGET_USER")"
case "$TARGET_BEFORE" in
  L) passwd -u "$TARGET_USER" ;;
  P) echo "$TARGET_USER is already in state P." ;;
  *) echo "ERROR: unexpected state $TARGET_BEFORE for $TARGET_USER; refusing." >&2; exit 1 ;;
esac

TARGET_AFTER="$(password_state "$TARGET_USER")"
ADMIN_AFTER="$(password_state "$ADMIN_USER")"
[[ "$TARGET_AFTER" == "P" ]] || { echo "ERROR: recovery state for $TARGET_USER is $TARGET_AFTER, expected P." >&2; exit 1; }
[[ "$ADMIN_AFTER" == "P" ]] || { echo "CRITICAL: $ADMIN_USER is $ADMIN_AFTER, expected P." >&2; exit 1; }
printf 'RECOVERY VERIFIED\n%s: %s\n%s: %s\n' "$TARGET_USER" "$TARGET_AFTER" "$ADMIN_USER" "$ADMIN_AFTER"
