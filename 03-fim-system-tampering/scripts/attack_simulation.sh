#!/bin/bash
# attack_simulation.sh
# Simulates FIM-triggering changes for Scenario 03

# remember chmod +x scripts/*.sh


echo "[*] Starting FIM attack simulation..."

# Soft change (should trigger 100030)
echo "[*] Soft change: modifying /etc/hosts"
echo "# fim-soft-test-$(date +%s)" >> /etc/hosts

sleep 3

# Critical change (should trigger 100031 → 100032 → possibly 100033)
echo "[*] Critical change: modifying /etc/passwd"
echo "fimtest:x:0:0::/root:/bin/bash" >> /etc/passwd

echo "[*] Simulation finished. Check Wazuh alerts for rules 100030-100033."
