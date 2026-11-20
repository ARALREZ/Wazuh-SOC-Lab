#!/usr/bin/env bash
set -Eeuo pipefail

WATCH_ROOT="/opt/wazuh-fim-lab/watch"
QUARANTINE_PARENT="/var/lib/wazuh-project03"
QUARANTINE_ROOT="${QUARANTINE_PARENT}/quarantine"
LOG_FILE="/var/log/wazuh-project03-quarantine.log"

ITEM_DIR=""
RESTORE_TMP=""

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

usage() {
    local program
    program="$(basename -- "$0")"
    cat <<EOF
Usage:
  $program init
  $program quarantine /opt/wazuh-fim-lab/watch/FILE
  $program restore /var/lib/wazuh-project03/quarantine/ITEM

Only regular files directly inside $WATCH_ROOT can be quarantined.
Restore accepts an item directory path or its item name.
EOF
}

need_command() {
    command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

sha256_file() {
    sha256sum -- "$1" | cut -d ' ' -f 1
}

# Stable identity signature: ctime is intentionally omitted because rename
# changes ctime even though it preserves the same inode and file contents.
stat_signature() {
    stat -c '%d:%i:%s:%u:%g:%a:%Y:%h' -- "$1"
}

# Captures metadata relevant to restore verification. POSIX ACLs are exposed
# as system.posix_acl_* xattrs on Linux and are included in this snapshot.
metadata_signature() {
    python3 - "$1" <<'PY'
import hashlib
import json
import os
import stat
import sys

path = sys.argv[1]
st = os.stat(path, follow_symlinks=False)
if not stat.S_ISREG(st.st_mode):
    raise SystemExit("metadata check requires a regular file")

xattrs = {}
for name in sorted(os.listxattr(path, follow_symlinks=False)):
    value = os.getxattr(path, name, follow_symlinks=False)
    xattrs[name] = {
        "size": len(value),
        "sha256": hashlib.sha256(value).hexdigest(),
    }

result = {
    "uid": st.st_uid,
    "gid": st.st_gid,
    "mode": stat.S_IMODE(st.st_mode),
    "size": st.st_size,
    "mtime_ns": st.st_mtime_ns,
    "xattrs": xattrs,
}
print(json.dumps(result, sort_keys=True, separators=(",", ":")))
PY
}

log_event() {
    local action="$1" original_path="$2" digest="$3" item_path="$4"

    python3 - "$LOG_FILE" "$action" "$original_path" "$digest" "$item_path" <<'PY'
import json
import os
import stat
import sys
from datetime import datetime, timezone

log_path, action, original_path, digest, item_path = sys.argv[1:]
flags = os.O_WRONLY | os.O_APPEND | os.O_CREAT | getattr(os, "O_NOFOLLOW", 0)
fd = os.open(log_path, flags, 0o600)
try:
    st = os.fstat(fd)
    if not stat.S_ISREG(st.st_mode) or st.st_uid != 0:
        raise RuntimeError("Log file is not a root-owned regular file")
    os.fchmod(fd, 0o600)
    record = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "action": action,
        "original_path": original_path,
        "sha256": digest,
        "quarantine_item": item_path,
    }
    data = (json.dumps(record, ensure_ascii=False) + "\n").encode("utf-8")
    written = os.write(fd, data)
    if written != len(data):
        raise RuntimeError("Incomplete log write")
    os.fsync(fd)
finally:
    os.close(fd)
PY
}

# Never delete a quarantine payload during error cleanup. An empty item
# directory can be removed, but a directory containing payload is recovery data.
cleanup_uncommitted_item() {
    if [[ -n "$ITEM_DIR" && -d "$ITEM_DIR" && ! -L "$ITEM_DIR" ]]; then
        if [[ ! -e "$ITEM_DIR/payload" && ! -L "$ITEM_DIR/payload" ]]; then
            rm -f -- "$ITEM_DIR/manifest.json" "$ITEM_DIR/manifest.json.tmp" 2>/dev/null || true
            rmdir -- "$ITEM_DIR" 2>/dev/null || true
        fi
    fi
    if [[ -n "$RESTORE_TMP" && -e "$RESTORE_TMP" && ! -L "$RESTORE_TMP" ]]; then
        rm -f -- "$RESTORE_TMP" 2>/dev/null || true
    fi
}
trap cleanup_uncommitted_item EXIT

require_root() {
    [[ "${EUID}" -eq 0 ]] || fail "Run this script with sudo/root."
}

prepare_layout() {
    [[ -d "$WATCH_ROOT" && ! -L "$WATCH_ROOT" ]] || fail "Watch directory missing or symlinked: $WATCH_ROOT"
    [[ "$(realpath -e -- "$WATCH_ROOT")" == "$WATCH_ROOT" ]] || fail "Watch directory path is not canonical: $WATCH_ROOT"

    for path in /var /var/lib "$QUARANTINE_PARENT" "$QUARANTINE_ROOT" /var/log; do
        [[ ! -L "$path" ]] || fail "Refusing symlink in system path: $path"
    done

    [[ -d /var/lib && -d /var/log ]] || fail "/var/lib or /var/log is unavailable."

    if [[ ! -e "$QUARANTINE_PARENT" ]]; then
        install -d -o root -g root -m 0700 -- "$QUARANTINE_PARENT"
    fi
    [[ -d "$QUARANTINE_PARENT" ]] || fail "Not a directory: $QUARANTINE_PARENT"
    [[ "$(stat -c '%u:%g' -- "$QUARANTINE_PARENT")" == "0:0" ]] || fail "Quarantine parent must be owned by root:root."
    chmod 0700 -- "$QUARANTINE_PARENT"

    if [[ ! -e "$QUARANTINE_ROOT" ]]; then
        install -d -o root -g root -m 0700 -- "$QUARANTINE_ROOT"
    fi
    [[ -d "$QUARANTINE_ROOT" && ! -L "$QUARANTINE_ROOT" ]] || fail "Invalid quarantine directory."
    [[ "$(stat -c '%u:%g' -- "$QUARANTINE_ROOT")" == "0:0" ]] || fail "Quarantine directory must be owned by root:root."
    chmod 0700 -- "$QUARANTINE_ROOT"

    [[ ! -L "$LOG_FILE" ]] || fail "Refusing symlink log file: $LOG_FILE"
    if [[ ! -e "$LOG_FILE" ]]; then
        install -o root -g root -m 0600 /dev/null "$LOG_FILE"
    fi
    [[ -f "$LOG_FILE" ]] || fail "Log path is not a regular file: $LOG_FILE"
    [[ "$(stat -c '%u:%g' -- "$LOG_FILE")" == "0:0" ]] || fail "Log file must be owned by root:root."
    chmod 0600 -- "$LOG_FILE"
}

validate_source_path() {
    local candidate="$1" resolved links

    [[ "$candidate" == "$WATCH_ROOT/"* ]] || fail "Source must be below $WATCH_ROOT."
    [[ "$candidate" != *$'\n'* && "$candidate" != *$'\r'* ]] || fail "Newline characters in paths are not supported."
    [[ ! -L "$candidate" ]] || fail "Symlinks are not allowed."
    [[ -f "$candidate" ]] || fail "Source must be an existing regular file."

    resolved="$(realpath -e -- "$candidate")" || fail "Cannot resolve source path."
    [[ "$resolved" == "$candidate" ]] || fail "Use a canonical path; symlinks and '..' traversal are refused."
    [[ "$(dirname -- "$resolved")" == "$WATCH_ROOT" ]] || fail "Only files directly inside $WATCH_ROOT are allowed."

    links="$(stat -c '%h' -- "$resolved")"
    [[ "$links" == "1" ]] || fail "Hard-linked files are refused (link count: $links)."
}

write_manifest() {
    local manifest_path="$1" original_path="$2" digest="$3" metadata_json="$4"

    python3 - "$manifest_path" "$original_path" "$digest" "$metadata_json" <<'PY'
import json
import os
import sys

manifest_path, original_path, digest, metadata_json = sys.argv[1:]
metadata = json.loads(metadata_json)
record = {
    "version": 2,
    "original_path": original_path,
    "sha256": digest,
    "metadata": metadata,
}
flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL | getattr(os, "O_NOFOLLOW", 0)
fd = os.open(manifest_path, flags, 0o600)
with os.fdopen(fd, "w", encoding="utf-8") as stream:
    json.dump(record, stream, ensure_ascii=False, sort_keys=True)
    stream.write("\n")
    stream.flush()
    os.fsync(stream.fileno())
PY
    chown root:root -- "$manifest_path"
    chmod 0600 -- "$manifest_path"
}

quarantine_file() {
    [[ "$#" -eq 1 ]] || { usage; exit 2; }
    local source="$1" before_sig before_hash before_meta after_sig after_hash after_meta
    local source_device quarantine_device item_name

    validate_source_path "$source"

    before_sig="$(stat_signature "$source")"
    before_hash="$(sha256_file "$source")"
    before_meta="$(metadata_signature "$source")"

    source_device="$(stat -c '%d' -- "$source")"
    quarantine_device="$(stat -c '%d' -- "$QUARANTINE_ROOT")"
    [[ "$source_device" == "$quarantine_device" ]] || fail "Source and quarantine must be on the same filesystem for atomic rename."

    ITEM_DIR="$(mktemp -d -- "$QUARANTINE_ROOT/item.XXXXXXXX")"
    chmod 0700 -- "$ITEM_DIR"
    chown root:root -- "$ITEM_DIR"

    # Same-filesystem mv uses atomic rename. It preserves the original inode,
    # ownership, mode, ACLs and extended attributes; no copy-then-delete window.
    mv -T -- "$source" "$ITEM_DIR/payload" || fail "Atomic move failed; inspect source and quarantine item."

    [[ -f "$ITEM_DIR/payload" && ! -L "$ITEM_DIR/payload" ]] || fail "Moved object is not a regular file; retained for manual recovery at $ITEM_DIR."

    after_sig="$(stat_signature "$ITEM_DIR/payload")"
    after_hash="$(sha256_file "$ITEM_DIR/payload")"
    after_meta="$(metadata_signature "$ITEM_DIR/payload")"

    # Write recovery metadata before reporting any verification anomaly.
    write_manifest "$ITEM_DIR/manifest.json" "$source" "$after_hash" "$after_meta"
    sync -f "$ITEM_DIR/payload"
    sync -f "$ITEM_DIR/manifest.json"
    sync -f "$ITEM_DIR"

    item_name="$(basename -- "$ITEM_DIR")"

    if [[ "$after_sig" != "$before_sig" || "$after_hash" != "$before_hash" || "$after_meta" != "$before_meta" ]]; then
        log_event "quarantine_anomaly" "$source" "$after_hash" "$ITEM_DIR"
        fail "Source identity/content/metadata changed during quarantine. Payload was retained for recovery: $ITEM_DIR"
    fi

    log_event "quarantine" "$source" "$after_hash" "$ITEM_DIR"

    printf '[PASS] File quarantined atomically.\n'
    printf 'ITEM: %s\n' "$ITEM_DIR"
    printf 'ITEM_NAME: %s\n' "$item_name"
    printf 'SHA256: %s\n' "$after_hash"
    printf 'RESTORE: sudo %s restore %s\n' "$0" "$ITEM_DIR"
}

read_manifest() {
    local manifest="$1"
    python3 - "$manifest" <<'PY'
import base64
import json
import os
import re
import stat
import sys

path = sys.argv[1]
st = os.lstat(path)
if not stat.S_ISREG(st.st_mode) or st.st_uid != 0:
    raise SystemExit("Invalid manifest file")
with open(path, "r", encoding="utf-8") as stream:
    data = json.load(stream)
version = data.get("version")
if version not in (1, 2):
    raise SystemExit("Unsupported manifest version")
original = data.get("original_path")
digest = data.get("sha256")
if not isinstance(original, str) or not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
    raise SystemExit("Invalid manifest path or SHA256")
if version == 1:
    # Backward compatibility: legacy manifests stored path and hash only.
    metadata = None
else:
    metadata = data.get("metadata")
    if not isinstance(metadata, dict):
        raise SystemExit("Invalid manifest metadata")
print(base64.b64encode(original.encode("utf-8")).decode("ascii"))
print(digest)
encoded_metadata = json.dumps(metadata, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
print(base64.b64encode(encoded_metadata.encode("utf-8")).decode("ascii"))
PY
}

restore_file() {
    [[ "$#" -eq 1 ]] || { usage; exit 2; }
    local item_input="$1" item_dir manifest payload item_real
    local -a manifest_fields
    local encoded_path expected_hash expected_meta_b64 expected_meta destination destination_parent parent_real

    case "$item_input" in
        "$QUARANTINE_ROOT"/*) item_dir="$item_input" ;;
        */*) fail "Use an item name or a direct path below $QUARANTINE_ROOT." ;;
        *) item_dir="$QUARANTINE_ROOT/$item_input" ;;
    esac

    [[ ! -L "$item_dir" && -d "$item_dir" ]] || fail "Quarantine item is missing or is a symlink."
    item_real="$(realpath -e -- "$item_dir")" || fail "Cannot resolve quarantine item."
    [[ "$item_real" == "$item_dir" && "$(dirname -- "$item_real")" == "$QUARANTINE_ROOT" ]] || fail "Quarantine item must be a direct child of $QUARANTINE_ROOT."
    [[ "$(stat -c '%u:%g:%a' -- "$item_dir")" == "0:0:700" ]] || fail "Quarantine item must be root-owned with mode 700."

    manifest="$item_dir/manifest.json"
    payload="$item_dir/payload"
    [[ -f "$manifest" && ! -L "$manifest" ]] || fail "Manifest missing or invalid."
    [[ -f "$payload" && ! -L "$payload" ]] || fail "Payload missing or invalid."
    [[ "$(stat -c '%h' -- "$payload")" == "1" ]] || fail "Payload has unexpected hard links."

    mapfile -t manifest_fields < <(read_manifest "$manifest")
    [[ "${#manifest_fields[@]}" -eq 3 ]] || fail "Could not parse quarantine manifest."
    encoded_path="${manifest_fields[0]}"
    expected_hash="${manifest_fields[1]}"
    expected_meta_b64="${manifest_fields[2]}"
    destination="$(printf '%s' "$encoded_path" | base64 --decode)" || fail "Invalid original path in manifest."
    expected_meta="$(printf '%s' "$expected_meta_b64" | base64 --decode)" || fail "Invalid metadata in manifest."

    [[ "$destination" == "$WATCH_ROOT/"* ]] || fail "Manifest destination is outside the permitted lab directory."
    [[ "$destination" != *$'\n'* && "$destination" != *$'\r'* ]] || fail "Invalid destination path in manifest."
    destination_parent="$(dirname -- "$destination")"
    [[ "$destination_parent" == "$WATCH_ROOT" ]] || fail "Restore destination must be directly inside the lab directory."
    [[ -d "$destination_parent" && ! -L "$destination_parent" ]] || fail "Original parent directory is missing or symlinked."
    parent_real="$(realpath -e -- "$destination_parent")" || fail "Cannot resolve original parent directory."
    [[ "$parent_real" == "$destination_parent" ]] || fail "Original parent path is not canonical; symlinked parent paths are refused."
    [[ "$parent_real" == "$WATCH_ROOT" ]] || fail "Original parent is outside the lab directory."

    [[ ! -e "$destination" && ! -L "$destination" ]] || fail "Restore refused: destination already exists. Nothing was overwritten."
    [[ "$(sha256_file "$payload")" == "$expected_hash" ]] || fail "Quarantine payload SHA256 mismatch."
    if [[ "$expected_meta" != "null" ]]; then
        [[ "$(metadata_signature "$payload")" == "$expected_meta" ]] || fail "Quarantine payload metadata/ACL/xattr mismatch."
    fi

    # Restore directly from the quarantined payload to preserve the original inode.
    # Hard links require both paths to reside on the same filesystem.
    [[ "$(stat -c '%d' -- "$payload")" == "$(stat -c '%d' -- "$destination_parent")" ]] ||
        fail "Restore requires payload and destination on the same filesystem to preserve inode."

    # Atomic hard-link creation fails rather than overwriting an existing destination.
    ln -- "$payload" "$destination" ||
        fail "Restore refused: destination appeared or hard link could not be created."

    # Verify that destination references the exact original quarantined inode.
    [[ "$(stat -c '%d:%i' -- "$destination")" == "$(stat -c '%d:%i' -- "$payload")" ]] ||
        fail "Restored inode identity mismatch. Keep quarantine payload for recovery."

    sync -f "$destination_parent"

    [[ "$(sha256_file "$destination")" == "$expected_hash" ]] || fail "Restored file hash verification failed. Keep quarantine item for recovery."
    if [[ "$expected_meta" != "null" ]]; then
        [[ "$(metadata_signature "$destination")" == "$expected_meta" ]] || fail "Restored metadata/ACL/xattr verification failed. Keep quarantine item for recovery."
    fi

    log_event "restore" "$destination" "$expected_hash" "$item_dir"

    rm -- "$payload" "$manifest"
    rmdir -- "$item_dir" || fail "File restored, but quarantine item directory contains unexpected files: $item_dir"

    printf '[PASS] File restored.\n'
    printf 'PATH: %s\n' "$destination"
    printf 'SHA256: %s\n' "$expected_hash"
}

main() {
    [[ "$#" -ge 1 ]] || { usage; exit 2; }
    case "$1" in
        -h|--help|help) usage; return 0 ;;
    esac

    require_root
    for command_name in realpath stat sha256sum cut cp mktemp install chmod chown sync python3 base64 ln rm rmdir dirname basename mv; do
        need_command "$command_name"
    done

    prepare_layout

    case "$1" in
        init)
            [[ "$#" -eq 1 ]] || { usage; exit 2; }
            printf '[PASS] Quarantine directory and log are ready.\n'
            printf 'QUARANTINE: %s\n' "$QUARANTINE_ROOT"
            printf 'LOG: %s\n' "$LOG_FILE"
            ;;
        quarantine) shift; quarantine_file "$@" ;;
        restore) shift; restore_file "$@" ;;
        *) usage; fail "Unknown operation: $1" ;;
    esac
}

main "$@"
