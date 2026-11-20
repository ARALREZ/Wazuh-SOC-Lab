# Lab Incident 03 — Persistence and Critical File Change

**Classification:** Persistence / sensitive file integrity event (lab simulation)  
**Rules:** `100033` cron, `100035` systemd, `100036` sensitive deletion, `100037` permissions/ownership  
**Endpoint:** `my-agent`, Agent `001`

## Executive summary

Project 03 includes controlled tests for cron and systemd persistence locations, sensitive-file deletion and permission/ownership changes. The tests were performed as separate scenarios where required so that correlation rule `100034` would not mask the individual final rule result.

## Evidence mapping

| Scenario | Evidence image | Required raw evidence |
|---|---|---|
| Cron change | `evidence/100033_cron_persistence.png` | Matching alert JSON |
| Systemd change | `evidence/100035_systemd_change.png` | Matching alert JSON and Who-data fields if present |
| Sensitive deletion | `evidence/100036_critical_file_deletion.png` | Matching alert JSON; note isolated correlation test |
| Permission/ownership change | `evidence/100037_permissions_change.png` | Matching alert JSON; note isolated correlation test |

## Investigation record

For each event, record the exact timestamp, path, rule ID, level, test ID and any Who-data actor/process fields from the alert. Do not combine different test IDs into a single event timeline.

The historical systemd test recorded login user `aralrez`, effective UID root, parent command `sudo` and process `bash`. Use those values only for the event that actually contains them; do not copy them to cron/deletion/permission scenarios without checking the alert.

## Analyst assessment

A cron or systemd modification may indicate persistence but can also be legitimate administration. A deletion or permission change may affect availability or security. Correlate the event with change approval, package/administrator activity and adjacent events before assigning malicious intent.

## Response and closure

Project 03 does not automatically quarantine system files. The lab utility must not be used on `/etc/cron*`, `/etc/systemd/system`, SSH files or other operating-system paths. Restore the controlled test environment through the specific test procedure and record the verification evidence.
