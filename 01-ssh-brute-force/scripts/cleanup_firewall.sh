#!/usr/bin/env bash

# chmod +x scripts/cleanup_firewall.sh
set -Eeuo pipefail

IP="${1:-192.168.122.112}"

LAB_CIDR="${LAB_CIDR:-192.168.122.0/24}"


# Validate IP and restrict cleanup to lab subnet.

python3 - "$IP" "$LAB_CIDR" <<'PY'

import ipaddress
import sys

ip = ipaddress.ip_address(sys.argv[1])
network = ipaddress.ip_network(sys.argv[2])

if ip.version != 4:
    raise SystemExit("[ERROR] IPv4 only.")

if ip not in network:
    raise SystemExit(
        f"[ERROR] IP outside lab network: {network}"
    )

PY


# Remove only the matching INPUT DROP rules.

REMOVED=0

while sudo iptables -C INPUT -s "$IP" -j DROP 2>/dev/null; do

    sudo iptables -D INPUT -s "$IP" -j DROP

    REMOVED=$((REMOVED + 1))

done


# Verify.

if sudo iptables -C INPUT -s "$IP" -j DROP 2>/dev/null; then

    echo "[ERROR] IP is still blocked: $IP"
    exit 1

fi


if (( REMOVED > 0 )); then

    echo "[PASS] Removed $REMOVED DROP rule(s) for $IP"

else

    echo "[INFO] No matching DROP rule found for $IP"

fi


echo "[INFO] Current INPUT rules:"

sudo iptables -S INPUT
