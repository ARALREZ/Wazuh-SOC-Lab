#!/bin/bash
# Wazuh Active Response Script: Block Attacker IP via iptables
# Leaves Wazuh agent connectivity unaffected (outbound TCP to manager).

ACTION=$1
USER=$2
IP=$3

# Path to log active response actions
LOG_FILE="/var/ossec/logs/active-responses.log"

if [ -z "$IP" ]; then
    echo "$(date): Error: No IP address provided to active response script." >> "$LOG_FILE"
    exit 1
fi

# Check if the IP is valid
if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$(date): Error: Invalid IP format: $IP" >> "$LOG_FILE"
    exit 1
fi

case "$ACTION" in
    add)
        # Block incoming traffic from the attacker IP
        iptables -A INPUT -s "$IP" -j DROP
        echo "$(date): SUCCESS: Blocked malicious IP $IP using iptables." >> "$LOG_FILE"
        ;;
    delete)
        # Unblock IP if needed
        iptables -D INPUT -s "$IP" -j DROP 2>/dev/null
        echo "$(date): SUCCESS: Unblocked IP $IP." >> "$LOG_FILE"
        ;;
    *)
        echo "$(date) data: Action $ACTION not implemented." >> "$LOG_FILE"
        exit 1
        ;;
esac

exit 0
