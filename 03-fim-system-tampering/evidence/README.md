# Project 03 — Evidence Register

**Scenario:** File Integrity Monitoring, Who-data and Manual Quarantine  
**Environment:** Wazuh 4.14.10-1; `my-agent` / Agent ID `001`; `my-server`  
**Evidence baseline:** 2026-11-19

## Evidence policy

Keep only evidence from the lab, with timestamps and source run IDs wherever available. Never commit `client.keys`, passwords, private keys, secrets or unredacted credentials. Screenshots and raw logs are separate evidence types. A filename alone does not prove that an image contains the expected alert; visually review the PNG before marking it accepted.

## Rule screenshots

| File | Required content | Local inventory status |
|---|---|---|
| `100030-fim-baseline-manager.png` | Manager alert, Agent 001, lab path, rule 100030 level 5 | Present per operator inventory; review before release |
| `100031_ssh_config_change.png` | SSH configuration change, rule 100031 level 10 | Present per operator inventory; review before release |
| `100032-authorized-keys-change-agent.png` | `authorized_keys` alert, rule 100032 level 12; Who-data if present; no key contents | Present per operator inventory; review before release |
| `100033_cron_persistence.png` | Cron change, rule 100033 level 12 | Present per operator inventory; review before release |
| `100034-sensitive-change-correlation.png` | Actual Manager alert 100034 level 14, correlation identity/window | Present per operator inventory; ensure it is a real alert, not `wazuh-logtest` |
| `100035_systemd_change.png` | Systemd change, rule 100035 level 12 | Present per operator inventory; review before release |
| `100036_critical_file_deletion.png` | Rule 100036 level 13; note isolated test | Present per operator inventory; review before release |
| `100037_permissions_change.png` | Rule 100037 level 12; note isolated test | Present per operator inventory; review before release |

## Manual quarantine screenshots

Store these PNGs in `evidence/quarantine/`.

| File | Required content | Status in latest handoff |
|---|---|---|
| `quarantine-01-file-isolated.png` | Quarantine PASS, item path, source absent, matching SHA256 | Captured by operator |
| `quarantine-02-file-restored.png` | Restore PASS, restored file, identical SHA256, item removed | Captured by operator |
| `quarantine-03-hash-metadata-verification.png` | SHA256, device/inode, UID/GID, mode, size before/after | Captured by operator |
| `quarantine-04-path-restrictions.png` | Outside-root and traversal refusals; fixture unchanged | Captured by operator |
| `quarantine-05-symlink-and-overwrite-protection.png` | Symlink/hardlink refused; restore conflict refused; blocker unchanged; restore after blocker removal | **Pending screenshot** |
| `quarantine-06-audit-log.png` | Exactly one quarantine and one restore JSONL record for the same run/path/hash | **Pending screenshot** |

Capture scripts are `scripts/evidence/capture-quarantine-05.sh` and `scripts/evidence/capture-quarantine-06.sh`. Run only on `my-agent` as root. Copy the resulting screenshots into this directory.

## Raw evidence files

| Location | Content |
|---|---|
| `alerts/` | Sanitized Manager alert extracts, including the real rule ID and original TEST_ID |
| `whodata/` | Who-data extracts; retain only fields actually present |
| `quarantine/` | Quarantine test reports, JSONL audit and quarantine screenshots |
| `../reports/test-runs/` | Regression console reports and summary JSON |

Existing records to preserve include:

- `alerts/p03-regression-20261117T183221Z-4501-fim-alerts.jsonl`
- `whodata/p03-regression-20261117T183221Z-4501-whodata.jsonl`
- `quarantine/p03-regression-20261117T183221Z-4501-quarantine-audit.jsonl`
- `quarantine/p03-stage3-quarantine-audit.jsonl`

The `p03-stage3` audit extract contains two `quarantine` and two `restore` records across the negative runner and the independent xattr test. Its SHA256 in the Fedora checkout was `8edeca61cec0855d05b8992daf5f1061cb5359167d7a77b3e7cc1ea3673bad6f`.

## Acceptance criteria

1. PNG opens and shows the actual run output.
2. Agent, rule ID or script operation and relevant path are readable.
3. Hashes match where integrity is claimed.
4. For rule 100034, the image shows a real `100034` level 14 Manager alert.
5. For Who-data, do not confuse `login_user.id` with effective `audit.user.id`.
6. For quarantine, show the actual command result, payload/source state and audit record.
7. Never label a synthetic `wazuh-logtest` event as live FIM or Active Response evidence.

<!-- P03_FINAL_VALIDATION_2026-11-20_START -->
## Latest evidence index — 2026-11-20

- Quarantine regression: `../reports/test-runs/p03-quarantine-regression-20261120T091758Z-5499-regression.log`
- Quarantine summary: `../reports/test-runs/p03-quarantine-regression-20261120T091758Z-5499-summary.json`
- Quarantine audit: `quarantine/p03-quarantine-regression-20261120T091758Z-5499-quarantine-audit.jsonl`
- Live FIM alerts: `alerts/p03-quarantine-regression-20261120T091758Z-5499-fim-alerts.jsonl`
- Historical rule alert export: `alerts/p03-rule-history-20261120T092321Z.jsonl`
- Screenshot inventory: `../reports/test-runs/p03-screenshot-inventory-20261120T092321Z.json`

The final validation report lists each expected screenshot and records whether the PNG file was present and valid.
<!-- P03_FINAL_VALIDATION_2026-11-20_END -->
