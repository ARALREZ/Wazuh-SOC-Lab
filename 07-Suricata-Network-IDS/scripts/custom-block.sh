#!/bin/bash
# ==============================================================================
# Script Name   : custom-block.sh
# Description   : SOAR Active Response script to block malicious IPs via iptables.
#                 Parses JSON alert payload from Wazuh Manager, extracts the 
#                 attacker's IP, and drops their traffic at the firewall level.
# Location      : /var/ossec/active-response/bin/custom-block.sh (on Agent)
# Author        : ARALREZ 
# ==============================================================================

# Read JSON payload passed by Wazuh Manager via standard input
read INPUT_JSON

# Extract the attacker's IP address
IP=$(echo "$INPUT_JSON" | grep -oP '"srcip":"\K[^"]+' | head -n 1)
if [ -z "$IP" ]; then
    IP=$(echo "$INPUT_JSON" | grep -oP '"src_ip":"\K[^"]+' | head -n 1)
fi

# If an IP is found, execute the block
if [ -n "$IP" ]; then
    iptables -I INPUT -s "$IP" -j DROP
    echo "$(date) - SOC-LAB Active Response: Zablokowano IP $IP za skanowanie sieciowe/webowe" >> /var/ossec/logs/active-responses.log
fi
