#!/bin/bash

echo "[*] Cleaning iptables rules on Agent..."
sudo iptables -F
sudo iptables -X
echo "[*] Firewall cleaned."

# remember:
# chmod +x scripts/cleanup_firewall.sh
