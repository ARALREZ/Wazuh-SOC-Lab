# Project 04 — Boundary Cases

These cases protect against threshold and identity mistakes. The regression runner generates fresh event timestamps and uses a separate `wazuh-logtest` session per case.

| Case | Expected outcome |
|---|---|
| Two denied attempts for one AUID | No 100041 or 100042 |
| Three denied attempts for one AUID within 90 seconds | 100041 on threshold |
| Four denied attempts for one AUID | No 100042 |
| Five denied attempts for one AUID within 120 seconds | 100042 on fifth event in the tuned lab ruleset |
| Five attempts spread across distinct AUIDs | No shared 100041/100042 correlation |
| `success=yes` | No P04 detection rule |
| Audit key other than `shadow_access` | No P04 detection rule |

The fifth-attempt behavior depends on the observed `frequency="4"` tuning in `wazuh/rules/linux_credential_access_rules.xml`. Re-run this suite after any rule-engine or rule-file change.
