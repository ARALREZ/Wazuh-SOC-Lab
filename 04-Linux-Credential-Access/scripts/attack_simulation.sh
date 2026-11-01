#!/bin/bash
# Attack simulation for Scenario 04

echo "[+] Scenario 04 - Credential Access simulation"
echo "[*] Running as user: $(whoami) (uid=$(id -u))"
echo

echo "[1/2] Single attempt (should trigger rule 100040)"
cat /etc/shadow 2>/dev/null || true
sleep 2

echo "[2/2] Multiple rapid attempts (should trigger 100041 → 100042 + Active Response)"
for i in {1..6}; do
    echo "  Attempt $i..."
    cat /etc/shadow 2>/dev/null || true
    sleep 2
done

echo
echo "[+] Attack finished."
echo "    Check Wazuh Dashboard for rules 100040 / 100041 / 100042"
echo "    Check: sudo tail -f /var/ossec/logs/active-responses.log"
echo "    Check: sudo iptables -L INPUT -n | grep DROP"
