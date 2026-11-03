#!/usr/bin/env bash
# chmod +x scripts/cleanup_firewall.sh
# ./scripts/cleanup_firewall.sh 192.168.122.112
set -Eeuo pipefail

IP="${1:-192.168.122.112}"

if ! python3 -c '
import ipaddress, sys
ipaddress.IPv4Address(sys.argv[1])
' "$IP"; then
    echo "[ERROR] Invalid IPv4 address: $IP"
    exit 1
fi

while sudo iptables -C INPUT -s "$IP" -j DROP 2>/dev/null; do
    sudo iptables -D INPUT -s "$IP" -j DROP
done

if sudo iptables -C INPUT -s "$IP" -j DROP 2>/dev/null; then
    echo "[ERROR] IP still blocked: $IP"
    exit 1
fi

echo "[PASS] IP unblocked: $IP"
