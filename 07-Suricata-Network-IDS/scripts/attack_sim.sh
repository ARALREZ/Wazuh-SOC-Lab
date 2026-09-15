#!/bin/bash
# ==============================================================================
# Script Name   : attack_sim.sh
# Description   : Simulates a network reconnaissance and web vulnerability scan.
#                 1. Generates HTTP traffic with an Nmap User-Agent.
#                 2. Performs a Stealth SYN Scan to trigger Suricata anomalies.
# Author        : ARALREZ 
# Target Host   : Agent (Victim) running Suricata + Wazuh
# ==============================================================================

TARGET_IP="192.168.122.X"

echo "[*] Step 1: Triggering Web Vulnerability Scanner rule (User-Agent)..."
for i in {1..6}; do 
    curl -A "Nmap Scripting Engine" http://$TARGET_IP/ --connect-timeout 2
    sleep 1
done

echo "[*] Step 2: Triggering Suricata Network Scan Correlation (Stealth SYN)..."
sudo nmap -sS -p 1-1000 --max-rate 20 $TARGET_IP

echo ""
echo "[*] Simulation script finished. Verify iptables for DROP rules."
