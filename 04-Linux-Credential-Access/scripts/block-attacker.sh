#!/bin/bash
# Scenario 04 - Local Credential Access containment
# Simple version without stdin (avoids hang on local audit events)
#
# Deploy:
#   sudo cp block-attacker.sh /var/ossec/active-response/bin/
#   sudo chown root:wazuh /var/ossec/active-response/bin/block-attacker.sh
#   sudo chmod 750 /var/ossec/active-response/bin/block-attacker.sh

LOG="/var/ossec/logs/active-responses.log"
DATE=$(date)

echo "$DATE - [block-attacker] START args=$*" >> "$LOG"

TARGET="aralrez"

if id "$TARGET" &>/dev/null; then
  passwd -l "$TARGET" >/dev/null 2>&1
  echo "$DATE - [block-attacker] LOCKED account: $TARGET" >> "$LOG"
else
  echo "$DATE - [block-attacker] User $TARGET not found" >> "$LOG"
fi

echo "$DATE - [block-attacker] END" >> "$LOG"
exit 0
