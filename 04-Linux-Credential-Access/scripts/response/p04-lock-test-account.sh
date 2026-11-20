#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="/var/ossec/logs/active-responses.log"
TARGET_USER="p04-labuser"

log_event() {
  printf '%s [P04-ActiveResponse] %s\n' "$(date -Is)" "$*" >> "$LOG_FILE"
}

if ! IFS= read -r INPUT_JSON; then
  log_event "ERROR: missing JSON input"
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  log_event "ERROR: jq is not installed"
  exit 1
fi

if ! jq -e . >/dev/null 2>&1 <<< "$INPUT_JSON"; then
  log_event "ERROR: invalid JSON input"
  exit 1
fi

COMMAND="$(jq -r '.command // empty' <<< "$INPUT_JSON")"
RULE_ID="$(jq -r '.parameters.alert.rule.id // empty' <<< "$INPUT_JSON")"
AUID="$(jq -r '.parameters.alert.audit.auid // .parameters.alert.data.audit.auid // empty' <<< "$INPUT_JSON")"

# Stateless response: only an add action is expected.
[[ "$COMMAND" == "add" ]] || {
  log_event "SKIP: unsupported command '${COMMAND:-empty}'"
  exit 0
}

[[ "$RULE_ID" == "100042" ]] || {
  log_event "SKIP: unexpected rule ID '${RULE_ID:-empty}'"
  exit 0
}

[[ "$AUID" =~ ^[0-9]+$ ]] || {
  log_event "SKIP: missing or invalid audit.auid"
  exit 0
}

id "$TARGET_USER" >/dev/null 2>&1 || {
  log_event "ERROR: allow-listed account does not exist: $TARGET_USER"
  exit 1
}

TARGET_UID="$(id -u "$TARGET_USER")"
[[ "$TARGET_UID" -ge 1000 && "$AUID" == "$TARGET_UID" ]] || {
  log_event "SKIP: alert AUID $AUID does not match $TARGET_USER UID $TARGET_UID"
  exit 0
}

PASSWORD_STATE="$(passwd -S "$TARGET_USER" | awk '{print $2}')"
case "$PASSWORD_STATE" in
  L)
    log_event "INFO: $TARGET_USER password is already locked"
    exit 0
    ;;
  P)
    ;;
  *)
    log_event "REFUSED: unexpected password state '$PASSWORD_STATE' for $TARGET_USER"
    exit 1
    ;;
esac

passwd -l "$TARGET_USER"
NEW_STATE="$(passwd -S "$TARGET_USER" | awk '{print $2}')"
[[ "$NEW_STATE" == "L" ]] || {
  log_event "ERROR: passwd -l returned but state is '$NEW_STATE'"
  exit 1
}

log_event "LOCKED password authentication for $TARGET_USER; rule=$RULE_ID auid=$AUID"
