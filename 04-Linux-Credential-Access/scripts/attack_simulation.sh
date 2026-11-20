#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="p04-labuser"
TARGET_UID="$(id -u "$TARGET_USER")"
CURRENT_USER="$(id -un)"
CURRENT_UID="$(id -u)"
LOGIN_UID="$(cat /proc/self/loginuid)"

printf '[P04] Credential Access live test\n'
printf 'user=%s uid=%s loginuid=%s\n' "$CURRENT_USER" "$CURRENT_UID" "$LOGIN_UID"

if [[ "$CURRENT_USER" != "$TARGET_USER" || "$CURRENT_UID" != "$TARGET_UID" || "$LOGIN_UID" != "$TARGET_UID" ]]; then
  echo "ERROR: start a real SSH login as $TARGET_USER; do not run through sudo or sudo -u." >&2
  exit 2
fi

for attempt in 1 2 3 4 5; do
  printf '[%s/5] Attempt to read /etc/shadow\n' "$attempt"
  if cat /etc/shadow >/dev/null 2>&1; then
    echo 'UNEXPECTED: read succeeded'
  else
    echo 'Expected: access denied'
  fi
  sleep 2
done

printf '[P04] Test finished. Check live Manager alerts 100040, 100041 and 100042.\n'
