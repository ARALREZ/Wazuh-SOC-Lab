# Test Results — SSH Brute Force Detection

**Date:** 2026-10-24  
**Environment:** Wazuh Manager 4.9.2 + Agent 4.9.2  
**Attacker:** Kali 192.168.122.112  
**Victim:** Ubunru-Agent 192.168.122.149  

## Positive Tests

| Test Case                        | Expected Result              | Observed     | Status |
|----------------------------------|------------------------------|--------------|--------|
| 3 failed logins                  | Rule 100001 (level 6)        | Alert fired  | PASS   |
| 5+ failed logins                 | Rule 100002 (level 10)       | Alert + AR   | PASS   |
| Successful login after brute     | Rule 100005 (level 14)       | Alert fired  | PASS   |
| Active Response (firewall-drop)  | IP blocked in iptables       | DROP present | PASS   |

## Negative / Whitelist Tests

| Test Case                        | Expected Result              | Observed     | Status |
|----------------------------------|------------------------------|--------------|--------|
| Failed logins from 192.168.122.1 | Rule 100010 (level 3) only   | Low-level    | PASS   |
| Normal single failed login       | No 100001/100002             | No high alert| PASS   |
| Clean successful login           | Only 5715                    | No 100005    | PASS   |

## Regression

| Check                            | Result |
|----------------------------------|--------|
| Rules load without error         | PASS   |
| Active Response triggers on 100002 | PASS |
| Correlation 100001 → 100005      | PASS   |

**Final Status:** PASS
