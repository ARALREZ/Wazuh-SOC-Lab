# Test Results - Scenario 04

| Test Case                        | Expected Result              | Status | Notes |
|----------------------------------|------------------------------|--------|-------|
| Single failed /etc/shadow access | Rule 100040 (level 7)        | PASS   |       |
| Multiple failed attempts         | Rule 100041 / 100042         | PASS   | 100041 may be absorbed by 100042 |
| Active Response triggered        | Account locked (`passwd -l`) | PASS   | Local attack – no srcip |
| Negative - sudo / su             | Low noise / filtered         | PARTIAL| audit rule still sees some sudo |
| Cleanup works                    | Account unlocked             | PASS   | `passwd -u aralrez` |

# Notes:
- Auditd – kernel-level monitoring of /etc/shadow
- Custom rules – layered detection (soft → medium → critical)
- Active Response – automated containment (local account lock)
