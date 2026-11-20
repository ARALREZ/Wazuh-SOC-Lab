# Project 04 — Expected Regression Results

The test runner must execute each case in its own `wazuh-logtest` process so previous correlation state does not leak into the next case.

| Scenario | Expected custom IDs |
|---|---|
| One denied event | `100040` |
| Two denied events, same AUID | `100040`; no `100041` / `100042` |
| Three denied events, same AUID | `100040`, `100041`; no `100042` |
| Four denied events, same AUID | `100040`, `100041`; no `100042` |
| Five denied events, same AUID | `100040`, `100041`, `100042` |
| Five denied events, different AUID values | `100040` only; no `100041` / `100042` |
| `success=yes` | No custom IDs |
| Unrelated Auditd key | No custom IDs |

`100042` currently uses `frequency="4"` to make the critical correlation appear on the fifth input event in the observed Wazuh 4.14.10 test sequence. This setting must be revalidated if the rule tree or parent/child rule logic changes.
