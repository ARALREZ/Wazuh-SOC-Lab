#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="p04-labuser"

if [[ "$EUID" -ne 0 ]]; then
  echo "Run with sudo: sudo $0" >&2
  exit 1
fi

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "Account $TARGET_USER does not exist; nothing to do."
  exit 0
fi

STATE="$(passwd -S "$TARGET_USER" | awk '{print $2}')"
if [[ "$STATE" == "L" ]]; then
  passwd -u "$TARGET_USER"
  echo "Unlocked password for $TARGET_USER."
else
  echo "No unlock needed; current password state is $STATE."
fi

passwd -S "$TARGET_USER"
echo "Administrator state (must remain P):"
passwd -S aralrez
