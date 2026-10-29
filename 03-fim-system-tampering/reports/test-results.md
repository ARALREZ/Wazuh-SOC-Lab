# Test Results - Scenario 03: FIM System Tampering

## Detection Test Results

| Test Case              | Input / Condition                          | Expected Result              | Status |
|------------------------|--------------------------------------------|------------------------------|--------|
| Soft detection         | Modification of /etc/hosts                 | Rule 100030 (level 7)        | PASS   |
| Critical file          | Modification of /etc/passwd                | Rule 100031 → 100032         | PASS   |
| Layered detection      | Soft change then critical change           | Rule 100033 (level 14)       | PASS   |
| Active Response        | After rule 100032 / 100033                 | quarantine-file.sh executed  | PASS   |
| Quarantine proof       | File locked + moved to quarantine          | chattr +i + file moved       | PASS   |
| Negative - normal      | Regular file change (non-critical)         | No high severity alert       | PASS   |

## Notes

- Tests performed with realtime FIM on Ubuntu agent.
- Active Response successfully quarantined `/etc/passwd`.
- Rule 100031 is a parent rule and usually does not appear as a separate alert when 100032/100033 fire.
