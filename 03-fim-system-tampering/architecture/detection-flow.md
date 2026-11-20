# Detection Flow — Project 03

## 1. Event source

A monitored file is added, modified, has attributes changed or is deleted on `my-agent`. FIM scope includes selected system directories and the dedicated lab directory `/opt/wazuh-fim-lab/watch`.

## 2. Collection and forwarding

The Wazuh Agent `001` on `my-agent` observes syscheck events. Who-data uses the audit provider where configured. Events are forwarded to `my-server` over the existing Wazuh transport (TCP/1514). Agent installation and enrollment belong to Project 00.

## 3. Rule evaluation

| Rule | Function | Level |
|---|---|---:|
| 100030 | Baseline FIM | 5 |
| 100031 | Sensitive account/authentication configuration | 10 |
| 100032 | SSH authorized_keys | 12 |
| 100033 | Cron persistence | 12 |
| 100034 | Correlated sensitive changes by audit UID | 14 |
| 100035 | Systemd persistence | 12 |
| 100036 | Sensitive file deletion | 13 |
| 100037 | Sensitive permission/ownership modification | 12 |

The full regular expressions and parent SIDs are defined by the XML file, not this summary.

## 4. Who-data interpretation

When present, retain `login_user.name`, `login_user.id`, effective `audit.user.id`, process, parent, working directory, timestamp, event type and affected path. Do not assume the login user and effective UID are identical. Do not claim a process field or timestamp that is absent from the actual alert.

## 5. Analyst decision and manual response

```text
FIM event -> Manager rule -> alert -> analyst triage
                                      |
                     +----------------+----------------+
                     |                |                |
                   monitor          investigate      manual quarantine
                                                       |
                                             restricted lab file only
                                                       |
                                               verify + audit + restore
```

No rule automatically moves a file. A matching alert does not itself prove malicious intent or a successful compromise.

## 6. Validation layers

1. Manager XML/config validation.
2. Real syscheck events and rule IDs in `alerts.json`.
3. Who-data field validation.
4. Negative lab-watch operations that should not trigger sensitive rules `100031–100037` (baseline `100030` is expected).
5. Manual quarantine and restore checks.
6. JSONL audit validation.

`wazuh-logtest` proves only that a supplied event matches a rule. It does not prove live file monitoring, audit attribution or quarantine behavior.
