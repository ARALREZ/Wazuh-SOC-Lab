#!/usr/bin/env bash
set -Eeuo pipefail

Q="/usr/local/sbin/wazuh-project03-quarantine"
WATCH="/opt/wazuh-fim-lab/watch"
QUAR="/var/lib/wazuh-project03/quarantine"
RUN_ID="p03-demo-q05-$(date -u +%Y%m%dT%H%M%SZ)-$$"
SYM_TARGET="$WATCH/${RUN_ID}-symlink-target.txt"
SYM="$WATCH/${RUN_ID}.symlink"
HARD1="$WATCH/${RUN_ID}-hard1.txt"
HARD2="$WATCH/${RUN_ID}-hard2.txt"
SRC="$WATCH/${RUN_ID}-overwrite.txt"
ITEM=""

[[ "$(hostname)" == "my-agent" ]] || { echo "[ERROR] Run this capture on my-agent"; exit 1; }
[[ "$EUID" -eq 0 ]] || { echo "[ERROR] Run with sudo: sudo bash $0"; exit 1; }
[[ -x "$Q" && -d "$WATCH" && -d "$QUAR" ]] || { echo "[ERROR] Quarantine layout missing"; exit 1; }

cleanup() {
  local rc=$?
  trap - EXIT
  set +e
  rm -f -- "$SYM" "$SYM_TARGET" "$HARD1" "$HARD2"
  if [[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" ]]; then
    if [[ ! -e "$SRC" ]]; then
      echo "[CLEANUP] Recovering own remaining quarantine item"
      "$Q" restore "$ITEM" || echo "[WARNING] Payload retained at $ITEM"
    fi
  fi
  if [[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" ]]; then
    echo "[WARNING] Preserve unrecovered payload: $ITEM"
  else
    rm -f -- "$SRC"
  fi
  exit "$rc"
}
trap cleanup EXIT

printf '%s\n' '========== PROJECT 03: SYMLINK / HARDLINK / OVERWRITE =========='
echo "HOST=$(hostname)"
echo "RUN_ID=$RUN_ID"
echo

echo "[1] SYMLINK PROTECTION"
printf 'Symlink target fixture\n' > "$SYM_TARGET"
ln -s "$SYM_TARGET" "$SYM"
if OUTPUT=$("$Q" quarantine "$SYM" 2>&1); then
  echo "$OUTPUT"; echo "[FAIL] Symlink accepted"; exit 1
else
  echo "$OUTPUT"; echo "[PASS] Symlink rejected"
fi
[[ -f "$SYM_TARGET" ]] || { echo "[FAIL] Symlink target changed"; exit 1; }
echo "SYMLINK_TARGET_UNCHANGED=YES"

echo
echo "[2] HARDLINK PROTECTION"
printf 'Hardlink fixture\n' > "$HARD1"
ln "$HARD1" "$HARD2"
echo "LINK_COUNT=$(stat -c '%h' "$HARD1")"
if OUTPUT=$("$Q" quarantine "$HARD2" 2>&1); then
  echo "$OUTPUT"; echo "[FAIL] Hardlink accepted"; exit 1
else
  echo "$OUTPUT"; echo "[PASS] Hardlink rejected"
fi
[[ -f "$HARD1" && -f "$HARD2" ]] || { echo "[FAIL] Hardlink fixture changed"; exit 1; }
echo "HARDLINK_FILES_UNCHANGED=YES"

echo
echo "[3] QUARANTINE OVERWRITE TEST FILE"
printf 'Original quarantined content\nRUN_ID=%s\n' "$RUN_ID" > "$SRC"
ORIGINAL_HASH=$(sha256sum "$SRC" | awk '{print $1}')
echo "ORIGINAL_SHA256=$ORIGINAL_HASH"
OUTPUT=$("$Q" quarantine "$SRC" 2>&1) || { echo "$OUTPUT"; exit 1; }
echo "$OUTPUT"
ITEM=$(printf '%s\n' "$OUTPUT" | sed -n 's/^ITEM: //p' | tail -n 1)
[[ -n "$ITEM" && -f "$ITEM/payload" ]] || { echo "[FAIL] Quarantine payload missing"; exit 1; }

echo
echo "[4] CREATE BLOCKER AND REFUSE RESTORE"
printf 'BLOCKER - MUST NOT BE OVERWRITTEN\n' > "$SRC"
BLOCKER_HASH=$(sha256sum "$SRC" | awk '{print $1}')
echo "BLOCKER_SHA256=$BLOCKER_HASH"
if OUTPUT=$("$Q" restore "$ITEM" 2>&1); then
  echo "$OUTPUT"; echo "[FAIL] Restore unexpectedly overwrote blocker"; exit 1
else
  echo "$OUTPUT"; echo "[PASS] Restore refused while destination exists"
fi
[[ -f "$ITEM/payload" ]] || { echo "[FAIL] Quarantine payload missing after refusal"; exit 1; }
[[ "$(sha256sum "$SRC" | awk '{print $1}')" == "$BLOCKER_HASH" ]] || { echo "[FAIL] Blocker changed"; exit 1; }
echo "BLOCKER_UNCHANGED=YES"
echo "QUARANTINE_PAYLOAD_RETAINED=YES"

echo
echo "[5] REMOVE OWN BLOCKER AND RESTORE"
rm -f -- "$SRC"
"$Q" restore "$ITEM"
ITEM=""
RESTORED_HASH=$(sha256sum "$SRC" | awk '{print $1}')
echo "RESTORED_SHA256=$RESTORED_HASH"
[[ "$ORIGINAL_HASH" == "$RESTORED_HASH" ]] || { echo "[FAIL] Restored hash mismatch"; exit 1; }
echo "[PASS] Original payload restored without overwrite"
echo
echo "[PASS] SYMLINK + HARDLINK + OVERWRITE PROTECTION VERIFIED"
