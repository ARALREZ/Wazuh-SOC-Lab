#!/bin/bash
# Cleanup after Scenario 04 tests

echo "[+] Cleaning up Scenario 04..."

for user in aralrez attacker testuser; do
  if id "$user" &>/dev/null; then
    passwd -u "$user" 2>/dev/null && echo "  Unlocked: $user"
  fi
done

echo "[*] Check iptables manually if needed: sudo iptables -L INPUT -n"
echo "[+] Cleanup finished."
