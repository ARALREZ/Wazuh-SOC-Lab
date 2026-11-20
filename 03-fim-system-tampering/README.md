# Project 03 — File Integrity Monitoring, Who-data and Manual Quarantine

**Status:** DONE
**Platform baseline:** Wazuh 4.14.10-1. Installation, package management and agent enrollment are maintained in [Project 00](../00-wazuh-installation-and-agent-deployment/README.md).  
**Evidence baseline:** 2026-11-19

## 1. Overview

Project 03 demonstrates file-integrity monitoring and system-tampering detection on the enrolled Ubuntu endpoint. Wazuh FIM (`syscheck`) observes selected system paths and a dedicated laboratory directory. Custom rules classify sensitive account/authentication changes, SSH authorized-key changes, cron/systemd persistence, critical-file deletion, permission/ownership changes and correlated activity. Where Who-data is available, an alert can include the login identity and process context associated with a filesystem event.

The response component is a **manual, administrator-invoked, reversible quarantine utility**. It is deliberately not connected to Wazuh Active Response. An administrator reviews an alert and chooses whether to quarantine a file. The utility is restricted to regular files directly inside `/opt/wazuh-fim-lab/watch`.

## 2. Scope and exclusions

Included:
- FIM monitoring and custom rules `100030–100037`;
- Who-data using the audit provider where configured;
- real alert evidence from `my-agent` to `my-server`;
- positive, negative and correlation validation;
- manual quarantine/restore, integrity verification and JSONL audit;
- incident investigation and risk documentation.

Not included:
- Wazuh installation, upgrade, agent enrollment or baseline platform connectivity (Project 00);
- automated quarantine through Active Response;
- `firewall-drop` or firewall changes;
- automatic deletion, permission-locking or immutable-attribute changes to production files;
- changes to other project scenarios.

## 3. Lab topology

| Host | Role | Operating system | Address |
|---|---|---|---|
| `my-server` | Wazuh Manager, Indexer and Dashboard | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| `my-agent` | Monitored endpoint, Wazuh Agent and FIM | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `Kali` | Authorized test host | Kali Linux | `192.168.122.112` |
| `Fedora` | Administration workstation / trusted source | Fedora | `192.168.122.1` as observed from the VM network; host interface also observed as `172.16.62.231` |

Agent ID: `001`. Wazuh Manager and Agent baseline: `4.14.10-1`. See Project 00 for the authoritative installation and enrollment record; do not duplicate installation instructions here.

## 4. Event and response flow

```text
File change on my-agent
        |
        v
Wazuh Agent syscheck / Who-data (audit provider)
        |
        | TCP/1514
        v
my-server — Wazuh Manager
        |
        +--> default syscheck rules
        +--> Project 03 rules 100030–100037
        +--> alerts.json / Dashboard
        |
        v
Administrator reviews alert and process context
        |
        +--> investigate / leave file / manual quarantine
                                     |
                                     v
                     wazuh-project03-quarantine
                                     |
                        restricted lab watch directory
                                     |
                     atomic move + manifest + JSONL audit
                                     |
                        manual restore after review
```

**Important:** alert generation and manual quarantine are separate operations. A FIM alert does not automatically invoke the quarantine script.

## 5. Detection rules

Rule source: `wazuh/rules/fim_system_tampering_rules.xml`.  
Deployed Manager file: `/var/ossec/etc/rules/fim_system_tampering_rules.xml`.

| Rule ID | Level | Purpose | Validation record |
|---|---:|---|---|
| `100030` | 5 | Baseline FIM event | Live lab-watch events and regression run |
| `100031` | 10 | Sensitive account/authentication configuration changes, including SSH/PAM/sudo-related paths | Live test of a temporary SSH configuration file |
| `100032` | 12 | SSH `authorized_keys` modification | Live test; Who-data context recorded in alert |
| `100033` | 12 | Cron persistence configuration modification | Live test |
| `100034` | 14 | Correlation of three or more sensitive changes associated with the same valid `audit_uid` within 300 seconds | Historically confirmed in lab; retain real `100034` alert evidence |
| `100035` | 12 | Systemd persistence configuration modification | Live test; Who-data context recorded |
| `100036` | 13 | Deletion of a monitored critical configuration file | Confirmed in isolated test with correlation temporarily disabled |
| `100037` | 12 | Permission or ownership changes to sensitive files | Confirmed in isolated test with correlation temporarily disabled |

Rule `100034` is a correlation rule. A later correlated alert can become the final alert for an event sequence; therefore individual rule evidence for `100036` and `100037` was gathered in isolation. Do not claim that every rule was proven by `wazuh-logtest`: the rules above have historical live-agent/manager validation records.

MITRE references present in the project rule set include `T1098.004` (SSH authorized keys), `T1053.003` (Cron) and `T1543.002` (Systemd service). Use the XML as the source of truth for exact mappings.

## 6. FIM and Who-data configuration

The project-specific configuration reference is `wazuh/configs/agent-fim.conf.example`. It is a **fragment**, not a replacement for `/var/ossec/etc/ossec.conf`.

Historical monitored paths include `/etc`, `/usr/bin`, `/usr/sbin`, `/bin`, `/sbin`, `/boot`, `/home/aralrez/.ssh`, `/var/spool/cron/crontabs` and `/opt/wazuh-fim-lab/watch`. The lab watch directory is `/opt/wazuh-fim-lab/watch`. Who-data was configured with the audit provider, `restart_audit=yes` and `startup_healthcheck=yes`.

The historical configuration includes broad and potentially overlapping paths. Final review should assess overlap and event volume before changing them. Preserve unrelated `ossec.conf` settings such as journald, Apache collection, audit log collection, ignore/nodiff and synchronization settings. Back up the existing file before any future change.

## 7. Manual quarantine design

| Item | Value |
|---|---|
| Repository script | `scripts/response/quarantine-file.sh` |
| Deployed command | `/usr/local/sbin/wazuh-project03-quarantine` |
| Allowed source root | `/opt/wazuh-fim-lab/watch` |
| Quarantine directory | `/var/lib/wazuh-project03/quarantine` |
| JSONL audit log | `/var/log/wazuh-project03-quarantine.log` |
| Deployed owner/mode | `root:root`, `0750` |
| Quarantine directory owner/mode | `root:root`, `0700` |
| Audit log owner/mode | `root:root`, `0600` |

The implementation validates canonical paths, rejects symlinks, hardlinks, FIFOs/special files, outside-root inputs and traversal. Source and quarantine are on the same filesystem (ext4 `/dev/vda2` in the recorded lab), so quarantine uses an atomic rename. A manifest records original path, SHA256 and metadata. Restore refuses to overwrite an existing destination and verifies the restored file. ACL and user xattr preservation were tested on concrete lab examples.

The deployed and repository script SHA256 recorded on 2026-11-19:

```text
fc53c7f50ce330d2415ec91d43b7832da78ec06721ab1b27b499181b21a37a1b
```

**Security boundary:** this utility is for controlled lab files only. Do not point it at arbitrary production paths. Do not connect it to Active Response without a separate design, threat model and explicit validation project.

## 8. Tests and validation layers

1. XML syntax and Manager analysis configuration validation.
2. Live FIM alerts for rules `100030–100037` (documented by rule-specific evidence).
3. Who-data attribution from actual alert records; do not infer absent fields.
4. Manual quarantine tests 1–11: regular file, hash/inode/metadata, restore, ACL, xattr, outside path, traversal, symlink/hardlink, FIFO, overwrite protection and JSONL audit.
5. Quarantine regression runner on `my-agent`.
6. Manager-side FIM integration check on `my-server` using the exact test ID.

`wazuh-logtest` validates rule matching only. It does not prove live event forwarding, Who-data, file movement, restore or firewall behavior.

See `tests/README.md`, `tests/regression/README.md` and `reports/test-results.md`.

## 9. Evidence

The root of `evidence/` contains the eight rule screenshots (`100030–100037`). `evidence/alerts/` stores sanitized alert extracts, `evidence/whodata/` stores Who-data extracts, and `evidence/quarantine/` stores test reports, audit records and the six quarantine screenshots.

The local project inventory contains all six quarantine screenshots (`quarantine-01` through `quarantine-06`). The PNG files must be opened and visually reviewed before publication.

See `evidence/README.md` for exact acceptance criteria.

## 10. Current status and known limitations

- Live rules `100030–100037`: historically validated; per-rule evidence is present in the local project tree according to the operator.
- Quarantine manual tests 1–11: reported PASS; the final independent Python xattr test also returned `FINAL_STATUS=PASS`.
- Negative runner `p03-stage3-negative-20261119T183501Z-3886`: `PASS=10`, `FAIL=0` for assertions covering tests 6–11.
- Historical broad regression `p03-regression-20261117T183221Z-4501`: `PASS=16`, `SKIP=1`, `FAIL=0`; the skip was xattr because `setfattr/getfattr` were unavailable in that version of the runner. This is historical, not the result of the corrected runner.
- A corrected repeatable runner must be executed after the manifest-v2 and Python xattr corrections in this package.
- One malformed/NUL-containing record was historically skipped by the Manager checker; the original `alerts.json` was not modified.
- No dedicated fault-injection test for audit-log write failure has been performed.
- No dedicated concurrency/race test has been performed.
- The lab watch directory is writable by `aralrez` (`750`); simultaneous modification remains a risk.

**Project status remains IN PROGRESS** until the corrected regression and Manager integration checks are executed, all evidence is reviewed, documentation is reconciled with resulting artifacts and final Git review is complete.

## 11. Related project

[Project 00 — Wazuh Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md)

<!-- P03_FINAL_VALIDATION_2026-11-20_START -->
## Latest validation — 2026-11-20

The latest quarantine regression completed with 19 PASS, 0 SKIP and 0 FAIL. The live negative FIM test produced 14 base-rule 100030 alerts and no high-severity 100031–100037 alerts for the benign watch fixture.

See [the final validation report](reports/test-runs/p03-final-validation-20261120T092321Z.md) and [the machine-readable summary](reports/test-runs/p03-final-validation-20261120T092321Z.json).

Project status remains **IN PROGRESS** pending final evidence review and selective Git publication.
<!-- P03_FINAL_VALIDATION_2026-11-20_END -->
