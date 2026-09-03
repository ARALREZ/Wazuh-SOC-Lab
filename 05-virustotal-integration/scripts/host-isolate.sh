#!/bin/bash
# SOAR Script: Quarantine Malicious File & Network Isolation

LOG_FILE="/var/ossec/logs/active-responses.log"
WAZUH_MANAGER_IP="192.168.122.X" # <--- Chcek your WAZUH IP

# Read JSON payload from stdin
read -r INPUT_JSON

# Extract alert file path using jq or grep
FILE_PATH=$(echo "$INPUT_JSON" | grep -oP '"file":"\K[^"]+')

echo "$(date) - [ACTIVE RESPONSE] Executing malware containment for file: $FILE_PATH" >> "$LOG_FILE"

# 1. Quarantine / Delete Malicious File
if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    rm -f "$FILE_PATH"
    echo "$(date) - [ACTIVE RESPONSE] File $FILE_PATH removed successfully." >> "$LOG_FILE"
fi

# 2. Network Isolation (iptables)
# Flush current rules and lock down interface
iptables -F
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Allow local loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow ONLY communication with Wazuh Manager
iptables -A INPUT -s "$WAZUH_MANAGER_IP" -j ACCEPT
iptables -A OUTPUT -d "$WAZUH_MANAGER_IP" -j ACCEPT

echo "$(date) - [ACTIVE RESPONSE] Host successfully isolated from network. Allowed connection to Manager: $WAZUH_MANAGER_IP" >> "$LOG_FILE"
