#!/usr/bin/env bash
set -Eeuo pipefail

Q="/usr/local/sbin/wazuh-project03-quarantine"
WATCH="/opt/wazuh-fim-lab/watch"
LOG="/var/log/wazuh-project03-quarantine.log"
RUN_ID="p03-demo-q06-$(date -u +%Y%m%dT%H%M%SZ)-$$"
SRC="$WATCH/${RUN_ID}.txt"
ITEM=""

[[ "$(hostname)" == "my-agent" ]] || { echo "[ERROR] Run this capture on my-agent"; exit 1; }
[[ "$EUID" -eq 0 ]] || { echo "[ERROR] Run with sudo: sudo bash $0"; exit 1; }
[[ -x "$Q" && -d "$WATCH" && -f "$LOG" ]] || { echo "[ERROR] Quarantine layout missing"; exit 1; }

cleanup() {
  local rc=$?
  trap - EXIT
  set +e
  if [[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" && ! -e "$SRC" ]]; then
    echo "[CLEANUP] Recovering own item"
    "$Q" restore "$ITEM" || echo "[WARNING] Preserve payload at $ITEM"
  fi
  if [[ -z "$ITEM" || ! -f "$ITEM/payload" ]]; then
    rm -f -- "$SRC"
  else
    echo "[WARNING] Preserve unrecovered payload: $ITEM"
  fi
  exit "$rc"
}
trap cleanup EXIT

printf '%s\n' '========== PROJECT 03: JSONL QUARANTINE AUDIT =========='
echo "HOST=$(hostname)"
echo "RUN_ID=$RUN_ID"
echo

echo "[1] CREATE FIXTURE"
printf 'Quarantine audit evidence\nRUN_ID=%s\n' "$RUN_ID" > "$SRC"
HASH_BEFORE=$(sha256sum "$SRC" | awk '{print $1}')
echo "SOURCE=$SRC"
echo "SHA256_BEFORE=$HASH_BEFORE"

echo
echo "[2] QUARANTINE"
OUTPUT=$("$Q" quarantine "$SRC" 2>&1) || { echo "$OUTPUT"; exit 1; }
echo "$OUTPUT"
ITEM=$(printf '%s\n' "$OUTPUT" | sed -n 's/^ITEM: //p' | tail -n 1)
[[ -n "$ITEM" && -f "$ITEM/payload" ]] || { echo "[FAIL] Payload not found"; exit 1; }

echo
echo "[3] RESTORE"
"$Q" restore "$ITEM"
ITEM=""
HASH_AFTER=$(sha256sum "$SRC" | awk '{print $1}')
echo "SHA256_AFTER=$HASH_AFTER"
[[ "$HASH_BEFORE" == "$HASH_AFTER" ]] || { echo "[FAIL] Restore hash mismatch"; exit 1; }

echo
echo "[4] FILTER REAL JSONL RECORDS FOR THIS FIXTURE"
python3 - "$LOG" "$SRC" "$HASH_BEFORE" <<'PY'
import json, sys
from collections import Counter
from datetime import datetime
log_path, expected_path, expected_hash = sys.argv[1:]
records = []
with open(log_path, encoding="utf-8") as stream:
    for number, line in enumerate(stream, 1):
        if not line.strip():
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError as exc:
            raise SystemExit(f"[FAIL] Invalid JSON at line {number}: {exc}")
        if record.get("original_path") == expected_path:
            records.append(record)
required = {"timestamp", "action", "original_path", "sha256", "quarantine_item"}
for record in records:
    if not required.issubset(record):
        raise SystemExit("[FAIL] Missing audit field")
    datetime.fromisoformat(record["timestamp"].replace("Z", "+00:00"))
    if record["sha256"] != expected_hash:
        raise SystemExit("[FAIL] Audit SHA256 mismatch")
actions = Counter(record["action"] for record in records)
print("===== ACTUAL JSONL RECORDS =====")
for record in records:
    print(json.dumps(record, sort_keys=True, ensure_ascii=False))
print()
print(f"TOTAL_RECORDS={len(records)}")
print(f"QUARANTINE={actions['quarantine']}")
print(f"RESTORE={actions['restore']}")
if len(records) != 2 or actions["quarantine"] != 1 or actions["restore"] != 1:
    raise SystemExit("[FAIL] Expected exactly one quarantine and one restore record")
print("[PASS] REAL JSONL AUDIT VERIFIED")
PY

echo
echo "[PASS] AUDIT LOG CONTAINS QUARANTINE AND RESTORE FOR SAME RUN"
