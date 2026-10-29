#!/bin/bash
# cleanup_fim.sh
# Restores files after FIM tests / quarantine

# remember chmod +x scripts/*.sh


echo "[*] Cleaning up FIM test artifacts..."

# Remove immutable flag and restore permissions
chattr -i /etc/passwd 2>/dev/null
chmod 644 /etc/passwd 2>/dev/null

chattr -i /etc/hosts 2>/dev/null
chmod 644 /etc/hosts 2>/dev/null

# Restore passwd from quarantine if it was moved
if ls /var/ossec/quarantine/passwd_* 1> /dev/null 2>&1; then
  echo "[*] Restoring /etc/passwd from quarantine..."
  cp /var/ossec/quarantine/passwd_* /etc/passwd
  chmod 644 /etc/passwd
fi

# Optional: clean test lines (careful!)
# sed -i '/fim-soft-test/d' /etc/hosts
# sed -i '/fimtest:x:0:0/d' /etc/passwd

echo "[*] Cleanup finished."
