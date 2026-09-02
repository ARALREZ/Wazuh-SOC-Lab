#!/bin/bash
# Read alert JSON from standard input
read INPUT_JSON

# Extract user ID / name from audit JSON
TARGET_UID=$(echo "$INPUT_JSON" | grep -oP '"uid":"\K[^"]+' | head -1)
TARGET_USER=$(id -nu "$TARGET_UID" 2>/dev/null)

# Extract source IP address if present in event or SSH logs
TARGET_IP=$(echo "$INPUT_JSON" | grep -oP '"srcip":"\K[^"]+' | head -1)
if [ -z "$TARGET_IP" ]; then
    TARGET_IP=$(echo "$INPUT_JSON" | grep -oP '"addr":"\K[^"]+' | head -1)
fi

# LOGGING
LOG_FILE="/var/ossec/logs/active-responses.log"

# --- SAFEGUARD 1: BLOCK USER ACCOUNT ---
# Never block root or main user aralrez
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ] && [ "$TARGET_USER" != "aralrez" ]; then
    passwd -l "$TARGET_USER"
    echo "$(date) - [ACTIVE RESPONSE] Account locked: $TARGET_USER (UID: $TARGET_UID)" >> "$LOG_FILE"
fi

# --- SAFEGUARD 2: PERMANENT IP BLOCK (IPTABLES) ---
# Never block localhost or empty IP
if [ -n "$TARGET_IP" ] && [ "$TARGET_IP" != "127.0.0.1" ] && [ "$TARGET_IP" != "0.0.0.0" ]; then
    # Check if rule already exists to avoid duplicates
    iptables -C INPUT -s "$TARGET_IP" -j DROP 2>/dev/null
    if [ $? -ne 0 ]; then
        iptables -A INPUT -s "$TARGET_IP" -j DROP
        # Save iptables permanently
        netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null
        echo "$(date) - [ACTIVE RESPONSE] Permanently blocked IP: $TARGET_IP" >> "$LOG_FILE"
    fi
fi
