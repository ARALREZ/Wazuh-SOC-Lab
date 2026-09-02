#!/bin/bash
# Custom Wazuh Active Response: Lock compromised user account

LOG_FILE="/var/ossec/logs/active-responses.log"
INPUT_JSON=$(cat -)

# Robust Username Extraction (JSON fields + Log Fallback)
TARGET_USER=$(echo "$INPUT_JSON" | grep -o '"srcuser":"[^"]*' | cut -d'"' -f4)
if [ -z "$TARGET_USER" ]; then
    TARGET_USER=$(echo "$INPUT_JSON" | grep -o '"user":"[^"]*' | cut -d'"' -f4)
fi
if [ -z "$TARGET_USER" ]; then
    TARGET_USER=$(echo "$INPUT_JSON" | grep -o 'sudo:[[:space:]]*[a-zA-Z0-9._-]*' | head -n1 | awk '{print $2}')
fi

ACTION=$1

if [ "$ACTION" = "add" ]; then
    if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
        usermod -L "$TARGET_USER"
        echo "$(date) - [Custom AR] LOCKED user account: $TARGET_USER due to rule trigger" >> "$LOG_FILE"
    fi
elif [ "$ACTION" = "delete" ]; then
    if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
        usermod -U "$TARGET_USER"
        echo "$(date) - [Custom AR] UNLOCKED user account: $TARGET_USER after timeout" >> "$LOG_FILE"
    fi
fi
