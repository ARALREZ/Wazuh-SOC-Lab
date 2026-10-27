#!/bin/bash
# Cleanup firewall rules after web attack tests (Scenario 02)

echo "[*] Cleaning iptables rules..."
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

echo "[+] Firewall cleaned. All traffic allowed."
sudo iptables -L -n
