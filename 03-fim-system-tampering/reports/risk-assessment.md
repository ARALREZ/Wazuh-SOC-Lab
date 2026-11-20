# Project 03 — Risk Assessment

**Scope:** Wazuh FIM/Who-data and manual quarantine in an isolated lab.  
**Assessment date:** 2026-11-19

## 1. Risk register

| ID | Risk | Impact | Existing control | Residual risk / action |
|---|---|---|---|---|
| R01 | False positive from broad FIM paths | Alert noise and analyst fatigue | Custom rules classify selected sensitive paths; baseline rule remains distinct | Review `/etc`, `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin` and `/boot` overlap and event volume before tuning |
| R02 | Who-data fields can be misinterpreted | Incorrect attribution | Store `login_user` separately from effective audit UID and process identity | Include only fields present in each alert; do not equate UID 0 with the original login user |
| R03 | Watch directory is writable by `aralrez` (`750`) | A file can change while an administrator is preparing quarantine | Tool validates path, object type, link count and hashes around atomic move | Restrict write access further if the lab design changes; no dedicated race test completed |
| R04 | Quarantine misapplied to production/system files | Service outage or loss of access | Utility only accepts canonical regular files directly inside `/opt/wazuh-fim-lab/watch` | Keep hardcoded boundary; do not broaden the allow-list casually |
| R05 | Restore destination already exists | Data overwrite | Restore refuses overwrite and retains quarantine payload | Resolve conflict manually; never delete the payload as cleanup |
| R06 | Audit log write failure | Incomplete audit trail | Root-owned regular file, mode `0600`, append and fsync behavior | Dedicated fault-injection test not performed |
| R07 | Race/concurrent source mutation | Inconsistent response or metadata | Same-filesystem atomic rename; pre/post hash and metadata checks | Atomic rename does not prove immunity to every race; concurrency test remains open |
| R08 | Filesystem/xattr differences | Some metadata may not be preserved on another filesystem | Concrete ACL and user xattr tests passed on ext4 `/dev/vda2` | Not tested for every xattr namespace or filesystem |
| R09 | Malformed historical `alerts.json` line containing NUL | Reporting parser may skip one record | Checker skips malformed line without modifying the original file | Preserve raw source; disclose skipped count in any derived report |
| R10 | Legacy Active Response wrapper accidentally re-enabled | Automated action outside current response policy | Current design is manual; legacy wrapper is not part of the active workflow | Keep wrapper under an explicitly labelled archive, not in the active response path |

## 2. Quarantine security properties

The reviewed utility is root-operated and uses a root-only quarantine directory (`0700`) and root-only audit log (`0600`). It refuses symbolic links, hardlinks, FIFOs/special files, outside-root paths and non-canonical traversal. Source and quarantine were verified on the same filesystem, allowing atomic rename. The manifest includes SHA256 and metadata; restore checks integrity and does not overwrite an existing destination.

These controls reduce the risk of accidental misuse in the lab. They are not a substitute for a production response design, independent authorization, backup strategy, concurrency analysis or fault-injection testing.

## 3. Response policy

Quarantine is manual and restricted to `/opt/wazuh-fim-lab/watch`. It is not wired into Wazuh Active Response and does not execute `firewall-drop`. An administrator must validate the alert and path, decide whether to isolate a lab file, preserve the audit evidence and restore the file after the test.

## 4. Operational recommendations

1. Keep the current allow-list narrow.
2. Back up `ossec.conf` before any future FIM path or Who-data changes.
3. Preserve the raw `alerts.json`; derive filtered evidence separately.
4. Verify the deployed and repository quarantine script hashes after every change.
5. Run the corrected regression runner and Manager-side integration checker after updating test code.
6. Keep Project 00 as the single source for Wazuh installation and enrollment details.
7. Do not claim complete coverage for audit-log fault injection, race conditions or all xattr namespaces.

<!-- P03_FINAL_VALIDATION_2026-11-20_START -->
## Validation and residual risks — 2026-11-20

The latest quarantine regression passed 19 checks with 0 skips and 0 failures.

The live negative watch test observed only rule 100030 for benign fixture operations. Sensitive rules 100031–100037 were not re-triggered during this finalization because doing so would require new changes to sensitive system paths. Their previous live test confirmations are recorded separately.

Residual limitations remain:
- No dedicated audit-log write fault-injection test.
- No dedicated concurrent race-condition test.
- ACL/xattr tests cover the tested Linux/ext4 examples, not all filesystems or namespaces.
- Quarantine remains manual, administrator-initiated and limited to `/opt/wazuh-fim-lab/watch`.

See `reports/test-runs/p03-final-validation-20261120T092321Z.md`.
<!-- P03_FINAL_VALIDATION_2026-11-20_END -->
