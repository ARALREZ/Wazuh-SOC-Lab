#!/usr/bin/env bash

# Read-only firewall inspection for Project 01.
# This script NEVER adds, deletes, flushes or changes firewall rules.

set -Eeuo pipefail

IP="${1:-192.168.122.112}"
LAB_CIDR="${LAB_CIDR:-192.168.122.0/24}"

python3 - "$IP" "$LAB_CIDR" <<'PY'
import ipaddress
import sys

try:
    ip = ipaddress.ip_address(sys.argv[1])
    network = ipaddress.ip_network(sys.argv[2], strict=False)
except ValueError as exc:
    raise SystemExit(f"[ERROR] Invalid IP or CIDR: {exc}")

if ip.version != 4:
    raise SystemExit("[ERROR] IPv4 only.")

if ip not in network:
    raise SystemExit(f"[ERROR] IP outside lab network: {network}")

print(f"[PASS] Inspecting lab IP: {ip}")
PY

echo
echo "===== IPv4 iptables rules mentioning $IP ====="

if ! command -v iptables-save >/dev/null 2>&1; then
    echo "[INFO] iptables-save is unavailable."
else
    sudo iptables-save |
        awk -v ip="$IP" '
            index($0, ip) {
                print
                found=1
            }
            END {
                if (!found) print "[INFO] No matching IPv4 rule found."
            }
        '
fi

echo
echo "===== nftables rules mentioning $IP ====="

if ! command -v nft >/dev/null 2>&1; then
    echo "[INFO] nft command is unavailable."
else
    sudo nft list ruleset |
        awk -v ip="$IP" '
            index($0, ip) {
                print
                found=1
            }
            END {
                if (!found) print "[INFO] No matching nftables line found."
            }
        '
fi

echo
echo "[INFO] Read-only inspection completed."
echo "[INFO] No firewall rules were changed."
echo "[INFO] Verify the Wazuh firewall-drop implementation before cleanup."
