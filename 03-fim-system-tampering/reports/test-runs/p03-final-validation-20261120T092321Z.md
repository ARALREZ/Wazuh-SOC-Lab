# Project 03 — final regression and evidence review (2026-11-20)

**Quarantine run:** `p03-quarantine-regression-20261120T091758Z-5499`

## Result summary

| Check | Result |
|---|---|
| Quarantine regression | PASS — 19 PASS / 0 SKIP / 0 FAIL |
| Rule XML IDs 100030–100037 | PASS |
| Local Bash/ShellCheck | PASS |
| Agent service and script hash | PASS |
| Manager analysisd validation | PASS |
| Live negative FIM test | PASS |
| Historical alert export | EXPORTED |
| Screenshot inventory | 14/15 valid PNG files |

## Quarantine regression

- Run ID: `p03-quarantine-regression-20261120T091758Z-5499`
- PASS: **19**
- SKIP: **0**
- FAIL: **0**
- Exit code: `0`
- Confirmed checks: atomic quarantine, SHA256, device/inode, owner/group, mode, size, mtime, ACL, xattr, restore, overwrite refusal, path restrictions, symlink/hardlink/FIFO rejection and JSONL audit validation.

## Live FIM negative test

- Source run: `p03-quarantine-regression-20261120T091758Z-5499`
- Manager observed 14 matching alerts, all rule `100030`, level 5.
- No rules 100031–100037 were triggered by the benign laboratory watch/quarantine operations in this run.
- This is the expected negative result for the lab watch fixture; it is not a new positive test of every high-level rule.

## Rule evidence review

| Rule | Historical test status from project records | Current/rotated Manager alert records exported |
|---|---|---:|
| `100030` | Base FIM; latest live negative test. | 16 |
| `100031` | Sensitive account/SSH configuration change; previous live test confirmation. | 0 |
| `100032` | authorized_keys modification; previous live test confirmation. | 0 |
| `100033` | Cron persistence; previous live test confirmation. | 0 |
| `100034` | Sensitive-change correlation; previously confirmed in an earlier live series. | 0 |
| `100035` | Systemd persistence/change; previous live test confirmation. | 0 |
| `100036` | Critical file deletion; previously tested in isolation. | 0 |
| `100037` | Permissions/ownership change; previously tested in isolation. | 0 |

The historical positive tests for 100031–100037 are not repeated by this non-destructive finalization run. The table distinguishes previous live test confirmation from the number of raw alert records still available in the Manager's current/rotated JSON alert archive. A zero archive count does not erase an earlier test result, but it means that the corresponding raw JSON record was not recovered in this export.

Rule 100034 had a prior confirmed live correlation series. A later specific run was not found in the current alert archive. Rules 100036 and 100037 were tested in isolation with the correlation rule temporarily disabled, as recorded in the project handoff.

## Screenshot inventory

Validated PNG files: **14/15**.

- `100030-fim-baseline-manager.png` — present (`evidence/100030-fim-baseline-manager.png`)
- `100031_ssh_config_change.png` — present (`evidence/100031_ssh_config_change.png`)
- `100032-authorized-keys-change-agent.png` — present (`evidence/100032-authorized-keys-change-agent.png`)
- `100033_cron_persistence.png` — present (`evidence/100033_cron_persistence.png`)
- `100034-sensitive-change-correlation.png` — present (`evidence/100034-sensitive-change-correlation.png`)
- `100035_systemd_change.png` — present (`evidence/100035_systemd_change.png`)
- `100036_critical_file_deletion.png` — present (`evidence/100036_critical_file_deletion.png`)
- `100037_permissions_change.png` — present (`evidence/100037_permissions_change.png`)
- `quarantine-01-file-isolated.png` — present (`evidence/quarantine/quarantine-01-file-isolated.png`)
- `quarantine-02-file-restored.png` — present (`evidence/quarantine/quarantine-02-file-restored.png`)
- `quarantine-03-hash-metadata-verification.png` — present (`evidence/quarantine/quarantine-03-hash-metadata-verification.png`)
- `quarantine-04-path-restrictions.png` — present (`evidence/quarantine/quarantine-04-path-restrictions.png`)
- `quarantine-05-symlink-and-overwrite-protection.png` — present (`evidence/quarantine/quarantine-05-symlink-and-overwrite-protection.png`)
- `quarantine-06-audit-log.png` — present (`evidence/quarantine/quarantine-06-audit-log.png`)
- `regression-summary.png` — missing/invalid

## Collected evidence

- Quarantine regression log: `reports/test-runs/p03-quarantine-regression-20261120T091758Z-5499-regression.log`
- Quarantine summary: `reports/test-runs/p03-quarantine-regression-20261120T091758Z-5499-summary.json`
- Quarantine audit: `evidence/quarantine/p03-quarantine-regression-20261120T091758Z-5499-quarantine-audit.jsonl`
- Latest FIM alert JSONL: `evidence/alerts/p03-quarantine-regression-20261120T091758Z-5499-fim-alerts.jsonl`
- Historical Manager alert export: `evidence/alerts/p03-rule-history-20261120T092321Z.jsonl`
- Screenshot inventory JSON: `reports/test-runs/p03-screenshot-inventory-20261120T092321Z.json`

## Limitations and residual risks

- The response remains manual and administrator-initiated; it is not Wazuh Active Response.
- The quarantine scope remains restricted to `/opt/wazuh-fim-lab/watch`.
- ACL and user xattr preservation were verified using the tested Linux/ext4 examples; this does not prove every filesystem or xattr namespace.
- A dedicated fault-injection test for audit-log write failure has not been performed.
- A dedicated concurrent race-condition test has not been performed.
- Historical `alerts.json` data may contain malformed/NUL lines. The export skips malformed records and does not alter the source log.
- This finalization does not re-trigger sensitive changes in `/etc`, `authorized_keys`, cron or systemd.

## Implementation identity

- Local script SHA256: `34535a1d7f88545b4afc2e887219ae687340f241b7d9451767c1f7a73c26d7cd`
- Agent script SHA256: `34535a1d7f88545b4afc2e887219ae687340f241b7d9451767c1f7a73c26d7cd`

**Project status remains IN PROGRESS** until all evidence and documentation have been reviewed and the selective Git publication is complete.
