#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT="${P03_QUARANTINE_SCRIPT:-/usr/local/sbin/wazuh-project03-quarantine}"
WATCH="${P03_WATCH_ROOT:-/opt/wazuh-fim-lab/watch}"
QUAR="${P03_QUARANTINE_ROOT:-/var/lib/wazuh-project03/quarantine}"
LOG="${P03_QUARANTINE_LOG:-/var/log/wazuh-project03-quarantine.log}"

[[ "$EUID" -eq 0 ]] || { echo "[ERROR] Run as root: sudo bash $0" >&2; exit 1; }
[[ "$(hostname)" == "my-agent" ]] || { echo "[ERROR] Run only on my-agent" >&2; exit 1; }
[[ -x "$SCRIPT" && -d "$WATCH" && ! -L "$WATCH" ]] || { echo "[ERROR] Script/watch missing" >&2; exit 1; }
[[ -d "$QUAR" && ! -L "$QUAR" && -f "$LOG" && ! -L "$LOG" ]] || { echo "[ERROR] Quarantine layout missing" >&2; exit 1; }

TEST_ID="p03-quarantine-regression-$(date -u +%Y%m%dT%H%M%SZ)-$$"
START_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SRC="$WATCH/${TEST_ID}.txt"
SYMLINK="$WATCH/${TEST_ID}.symlink"
SYMLINK_TARGET="$WATCH/${TEST_ID}-symlink-target.txt"
FIFO="$WATCH/${TEST_ID}.fifo"
HARD1="$WATCH/${TEST_ID}-hard1.txt"
HARD2="$WATCH/${TEST_ID}-hard2.txt"
OUTSIDE="/tmp/${TEST_ID}-outside.txt"
ITEM=""
ITEM_LINK="$QUAR/${TEST_ID}-item-link"
ACL_ENABLED=0
XATTR_ENABLED=0
ACL_BEFORE=""
XATTR_VALUE="$TEST_ID-user-xattr"
PASS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0
REPORT_FILE="/var/tmp/${TEST_ID}-regression.log"
SUMMARY_FILE="/var/tmp/${TEST_ID}-summary.json"
AUDIT_EXPORT="/var/tmp/${TEST_ID}-quarantine-audit.jsonl"

exec > >(tee "$REPORT_FILE") 2>&1
pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo "[PASS] $*"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); echo "[SKIP] $*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo "[FAIL] $*" >&2; exit 1; }

expect_rejected() {
  local label="$1" output
  shift
  if output=$("$@" 2>&1); then
    echo "$output"
    fail "$label was unexpectedly accepted"
  else
    echo "$output"
    pass "$label rejected"
  fi
}

cleanup() {
  local rc=$?
  trap - EXIT
  set +e
  # Recover only this run's own item. Never delete an unrecovered payload.
  if [[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" && ! -e "$SRC" ]]; then
    echo "[CLEANUP] Attempting restore of this run's item: $ITEM"
    "$SCRIPT" restore "$ITEM" || echo "[WARNING] Payload retained for manual recovery at $ITEM"
  fi
  rm -f -- "$SYMLINK" "$SYMLINK_TARGET" "$FIFO" "$HARD1" "$HARD2" "$OUTSIDE" "$ITEM_LINK"
  if [[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" ]]; then
    echo "[WARNING] Do not delete this unrecovered payload: $ITEM"
  else
    rm -f -- "$SRC"
  fi
  python3 - "$SUMMARY_FILE" "$TEST_ID" "$START_UTC" "$PASS_COUNT" "$SKIP_COUNT" "$FAIL_COUNT" "$rc" "$REPORT_FILE" "$AUDIT_EXPORT" <<'PY_SUMMARY'
import datetime, json, os, socket, sys
path, test_id, started, passed, skipped, failed, rc, report, audit = sys.argv[1:]
data = {
  "test_id": test_id,
  "started_utc": started,
  "finished_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
  "host": socket.gethostname(),
  "pass": int(passed), "skip": int(skipped),
  "fail": int(failed) if int(failed) else (0 if int(rc) == 0 else 1),
  "exit_code": int(rc), "console_report": report,
  "quarantine_audit_export": audit if os.path.isfile(audit) else None,
}
with open(path, "w", encoding="utf-8") as stream:
  json.dump(data, stream, indent=2); stream.write("\n")
PY_SUMMARY
  echo "REPORT_FILE: $REPORT_FILE"
  echo "SUMMARY_FILE: $SUMMARY_FILE"
  [[ -f "$AUDIT_EXPORT" ]] && echo "AUDIT_EXPORT: $AUDIT_EXPORT"
  if [[ "$rc" -eq 0 ]]; then echo "FINAL_STATUS=PASS"; else echo "FINAL_STATUS=FAIL"; fi
  exit "$rc"
}
trap cleanup EXIT

printf 'TEST_ID: %s\nHOST: %s\nSCRIPT: %s\n' "$TEST_ID" "$(hostname)" "$SCRIPT"

# 1. Initialization and protected permissions.
"$SCRIPT" init
[[ "$(stat -c '%u:%g:%a' "$QUAR")" == "0:0:700" ]] || fail "Quarantine directory is not root:root 0700"
[[ "$(stat -c '%u:%g:%a' "$LOG")" == "0:0:600" ]] || fail "Audit log is not root:root 0600"
pass "Initialization and secure directory/log permissions"

# 2. Fixture, optional ACL and Python xattr.
printf 'Project 03 quarantine regression fixture\nTEST_ID=%s\n' "$TEST_ID" > "$SRC"
chmod 0640 "$SRC"
touch -d '2026-01-15 12:34:56 UTC' "$SRC"
if command -v setfacl >/dev/null 2>&1 && command -v getfacl >/dev/null 2>&1; then
  ACL_UID="$(id -u aralrez 2>/dev/null || true)"
  if [[ -n "$ACL_UID" ]] && setfacl -m "u:${ACL_UID}:r--" "$SRC"; then
    ACL_ENABLED=1
    ACL_BEFORE="$(getfacl -cp -- "$SRC")"
    pass "POSIX ACL test fixture configured"
  else
    skip "POSIX ACL could not be configured on this filesystem"
  fi
else
  skip "setfacl/getfacl unavailable; POSIX ACL preservation not exercised"
fi
set +e
python3 - "$SRC" "$XATTR_VALUE" <<'PY_XATTR_SETUP'
import os, sys
try:
    os.setxattr(sys.argv[1], "user.p03_test", sys.argv[2].encode(), follow_symlinks=False)
    value = os.getxattr(sys.argv[1], "user.p03_test", follow_symlinks=False)
    raise SystemExit(0 if value == sys.argv[2].encode() else 1)
except OSError:
    raise SystemExit(2)
PY_XATTR_SETUP
XATTR_RC=$?
set -e
if [[ "$XATTR_RC" -eq 0 ]]; then
  XATTR_ENABLED=1
  pass "User xattr fixture configured through Python os.setxattr/os.getxattr"
elif [[ "$XATTR_RC" -eq 2 ]]; then
  skip "Filesystem does not support user xattr on this fixture"
else
  fail "Python xattr fixture setup failed"
fi

HASH_BEFORE="$(sha256sum "$SRC" | awk '{print $1}')"
STAT_BEFORE="$(stat -c '%d:%i:%s:%u:%g:%a:%Y:%h' "$SRC")"
echo "SHA256_BEFORE=$HASH_BEFORE"
echo "STAT_BEFORE=$STAT_BEFORE"

# 3. Quarantine and verify payload.
Q_OUTPUT="$("$SCRIPT" quarantine "$SRC" 2>&1)" || { echo "$Q_OUTPUT"; fail "Quarantine command failed"; }
echo "$Q_OUTPUT"
ITEM="$(printf '%s\n' "$Q_OUTPUT" | sed -n 's/^ITEM: //p' | tail -n 1)"
[[ -n "$ITEM" && -d "$ITEM" && -f "$ITEM/payload" && -f "$ITEM/manifest.json" ]] || fail "Payload/manifest not found"
[[ ! -e "$SRC" && ! -L "$SRC" ]] || fail "Source still exists after quarantine"
[[ "$(stat -c '%u:%g:%a' "$ITEM")" == "0:0:700" ]] || fail "Item directory not root:root 0700"
HASH_PAYLOAD="$(sha256sum "$ITEM/payload" | awk '{print $1}')"
STAT_PAYLOAD="$(stat -c '%d:%i:%s:%u:%g:%a:%Y:%h' "$ITEM/payload")"
[[ "$HASH_PAYLOAD" == "$HASH_BEFORE" ]] || fail "Payload SHA256 mismatch"
[[ "$STAT_PAYLOAD" == "$STAT_BEFORE" ]] || fail "Payload identity/metadata mismatch"
pass "Atomic quarantine, source removal, payload SHA256, inode and metadata"

# 4. Validate manifest v2 (the schema actually emitted by current utility).
python3 - "$ITEM/manifest.json" "$SRC" "$HASH_BEFORE" <<'PY_MANIFEST'
import json, os, stat, sys
path, original, digest = sys.argv[1:]
st = os.lstat(path)
if not stat.S_ISREG(st.st_mode) or st.st_uid != 0 or stat.S_IMODE(st.st_mode) != 0o600:
    raise SystemExit("[FAIL] Manifest must be root-owned regular file mode 0600")
with open(path, encoding="utf-8") as stream:
    m = json.load(stream)
if m.get("version") != 2 or m.get("original_path") != original or m.get("sha256") != digest:
    raise SystemExit("[FAIL] Manifest version/path/hash mismatch")
meta = m.get("metadata")
if not isinstance(meta, dict) or not {"uid", "gid", "mode", "size", "mtime_ns", "xattrs"}.issubset(meta):
    raise SystemExit("[FAIL] Manifest v2 metadata fields missing")
print("[PASS] Manifest v2 schema, source path, SHA256 and metadata")
PY_MANIFEST
pass "Manifest version 2 validation"
if [[ "$ACL_ENABLED" -eq 1 ]]; then
  [[ "$(getfacl -cp -- "$ITEM/payload")" == "$ACL_BEFORE" ]] || fail "ACL changed inside quarantine payload"
  pass "ACL preserved in quarantine payload"
fi
if [[ "$XATTR_ENABLED" -eq 1 ]]; then
  python3 - "$ITEM/payload" "$XATTR_VALUE" <<'PY_XATTR_PAYLOAD'
import os, sys
actual = os.getxattr(sys.argv[1], "user.p03_test", follow_symlinks=False)
if actual != sys.argv[2].encode(): raise SystemExit("[FAIL] xattr mismatch in payload")
print("[PASS] User xattr preserved in quarantine payload")
PY_XATTR_PAYLOAD
  pass "User xattr verified in quarantine payload"
fi

# 5. Restore must refuse to overwrite a pre-existing destination.
printf 'CONFLICT FILE - MUST NOT BE OVERWRITTEN\nTEST_ID=%s\n' "$TEST_ID" > "$SRC"
CONFLICT_HASH="$(sha256sum "$SRC" | awk '{print $1}')"
expect_rejected "Restore with existing destination" "$SCRIPT" restore "$ITEM"
[[ "$(sha256sum "$SRC" | awk '{print $1}')" == "$CONFLICT_HASH" ]] || fail "Conflict destination changed"
[[ -f "$ITEM/payload" && -f "$ITEM/manifest.json" ]] || fail "Payload/manifest removed after refused restore"
pass "Conflict destination and quarantine payload remain intact"
rm -f -- "$SRC"

# 6. Successful restore and metadata checks.
RESTORE_OUTPUT="$("$SCRIPT" restore "$ITEM" 2>&1)" || { echo "$RESTORE_OUTPUT"; fail "Restore failed"; }
echo "$RESTORE_OUTPUT"
ITEM=""
[[ -f "$SRC" && ! -L "$SRC" ]] || fail "Restored source missing"
HASH_AFTER="$(sha256sum "$SRC" | awk '{print $1}')"
STAT_AFTER="$(stat -c '%d:%i:%s:%u:%g:%a:%Y:%h' "$SRC")"
[[ "$HASH_AFTER" == "$HASH_BEFORE" ]] || fail "Restored SHA256 mismatch"
[[ "$STAT_AFTER" == "$STAT_BEFORE" ]] || fail "Restored metadata/inode mismatch"
pass "Restored SHA256, device/inode, owner/group, mode, size and mtime"
if [[ "$ACL_ENABLED" -eq 1 ]]; then
  [[ "$(getfacl -cp -- "$SRC")" == "$ACL_BEFORE" ]] || fail "ACL mismatch after restore"
  pass "ACL preserved after restore"
fi
if [[ "$XATTR_ENABLED" -eq 1 ]]; then
  python3 - "$SRC" "$XATTR_VALUE" <<'PY_XATTR_RESTORE'
import os, sys
actual = os.getxattr(sys.argv[1], "user.p03_test", follow_symlinks=False)
if actual != sys.argv[2].encode(): raise SystemExit("[FAIL] xattr mismatch after restore")
print("[PASS] User xattr preserved after restore")
PY_XATTR_RESTORE
  pass "User xattr preserved after restore"
fi

# 7. Negative input tests, with unique fixture names for this TEST_ID.
printf 'symlink target fixture\n' > "$SYMLINK_TARGET"
ln -s "$SYMLINK_TARGET" "$SYMLINK"
expect_rejected "Symlink source" "$SCRIPT" quarantine "$SYMLINK"
mkfifo "$FIFO"
expect_rejected "FIFO/special file" "$SCRIPT" quarantine "$FIFO"
printf 'Hardlink fixture\n' > "$HARD1"
ln "$HARD1" "$HARD2"
expect_rejected "Hard-linked source" "$SCRIPT" quarantine "$HARD1"
printf 'Outside fixture\n' > "$OUTSIDE"
expect_rejected "Outside-watch path" "$SCRIPT" quarantine "$OUTSIDE"
expect_rejected "Path traversal" "$SCRIPT" quarantine "$WATCH/../watch/$(basename "$SRC")"
ln -s "$QUAR/nonexistent-item" "$ITEM_LINK"
expect_rejected "Symlink quarantine item on restore" "$SCRIPT" restore "$ITEM_LINK"
rm -f -- "$ITEM_LINK"

# 8. Validate and export exactly this run's two audit records.
python3 - "$LOG" "$SRC" "$HASH_BEFORE" "$AUDIT_EXPORT" <<'PY_AUDIT'
import json, sys
from collections import Counter
from datetime import datetime
log_path, expected_path, digest, export_path = sys.argv[1:]
records=[]
with open(log_path, encoding="utf-8") as stream:
  for line_number, line in enumerate(stream, 1):
    if not line.strip(): continue
    try: record=json.loads(line)
    except ValueError as exc: raise SystemExit(f"[FAIL] Invalid JSON line {line_number}: {exc}")
    if record.get("original_path") == expected_path: records.append(record)
required={"timestamp","action","original_path","sha256","quarantine_item"}
for record in records:
  if not required.issubset(record): raise SystemExit("[FAIL] Required audit keys missing")
  datetime.fromisoformat(record["timestamp"].replace("Z", "+00:00"))
  if record["sha256"] != digest: raise SystemExit("[FAIL] Audit hash mismatch")
actions=Counter(r["action"] for r in records)
if len(records)!=2 or actions["quarantine"]!=1 or actions["restore"]!=1:
  raise SystemExit(f"[FAIL] Expected quarantine+restore pair; found {actions}")
with open(export_path,"w",encoding="utf-8") as out:
  for r in records: out.write(json.dumps(r,ensure_ascii=False,sort_keys=True)+"\n")
for r in records: print(json.dumps(r,ensure_ascii=False,sort_keys=True))
print("[PASS] JSONL syntax, schema, timestamps, SHA256 and quarantine/restore pair")
PY_AUDIT
pass "JSONL audit validation and run-specific export"

printf '\n========== REGRESSION SUMMARY ==========\n'
echo "TEST_ID=$TEST_ID"
echo "PASS=$PASS_COUNT"
echo "SKIP=$SKIP_COUNT"
echo "FAIL=$FAIL_COUNT"
echo "REPORT=$REPORT_FILE"
echo "SUMMARY=$SUMMARY_FILE"
echo "AUDIT_EXPORT=$AUDIT_EXPORT"
echo "[PASS] QUARANTINE REGRESSION COMPLETED"
