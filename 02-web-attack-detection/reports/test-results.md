# Test Results - Scenario 02: Web Attack Detection

| Rule ID | Description                         | Level | Status | Notes                              |
|---------|-------------------------------------|-------|--------|------------------------------------|
| 100020  | Soft Scanner (User-Agent)           | 6     | PASS   | Nikto / sqlmap detected            |
| 100021  | SQL Injection                       | 10    | PASS   | Classic SQLi payloads              |
| 100022  | XSS                                 | 10    | PASS   | script / javascript payloads       |
| 100023  | Path Traversal / LFI                | 10    | PASS   | ../etc/passwd                      |
| 100024  | Command Injection                   | 11    | PASS   | ;id / \|whoami                     |
| 100025  | Multiple scanners (correlation)     | 8     | PASS   | 4x scanner in short time           |
| 100026  | Multiple attack types (correlation) | 12    | PASS   | 3 different techniques from same IP|
| 100027  | Attack after scanner (layered)      | 13    | PASS   | Scanner → then SQLi/XSS            |
| 100028  | Trusted IP                          | 3     | PASS   | From 192.168.122.1                 |
| 100029  | Suspicious patterns                 | 5     | PASS   | php:// / eval / data://            |

**Active Response:** PASS (firewall-drop triggered, IP blocked)

**Date:** 2026-10-27  
**Environment:** Wazuh Manager 4.x + Ubuntu Agent + Apache2
