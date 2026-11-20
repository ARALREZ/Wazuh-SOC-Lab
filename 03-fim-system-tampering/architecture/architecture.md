# Architecture — Project 03: FIM, Who-data and Manual Quarantine

## 1. Purpose

Project 03 monitors file-system changes on `my-agent`, classifies security-relevant modifications with custom Wazuh rules and provides a separate administrator-operated quarantine utility for controlled laboratory files. Detection and response are intentionally decoupled.

## 2. Lab components

| Host | Role | Address |
|---|---|---|
| `my-agent` | Ubuntu endpoint, Wazuh Agent, syscheck and auditd/Who-data | `192.168.122.208` |
| `my-server` | Wazuh Manager, rule evaluation and alerts | `192.168.122.178` |
| Kali | Authorized test host | `192.168.122.112` |
| Fedora | Administration workstation / trusted source | `192.168.122.1` as seen from the VM network |

Platform installation, package versions and agent enrollment are owned by Project 00.

## 3. Logical components

```text
+---------------------------+
| my-agent                  |
| Ubuntu 24.04.5            |
| Wazuh Agent               |
| syscheck + auditd Who-data|
| monitored paths + lab watch|
+-------------+-------------+
              | Wazuh TCP/1514
              v
+---------------------------+
| my-server                 |
| Wazuh Manager             |
| default syscheck rules    |
| Project 03 rules 100030-37|
| alerts.json               |
+-------------+-------------+
              |
              v
+---------------------------+
| Dashboard / analyst review|
+---------------------------+

Separate manual response path:
Administrator -> quarantine CLI -> lab watch -> quarantine store
                                   ^                  |
                                   +---- manual restore
```

## 4. Detection layer

The custom rule file is `wazuh/rules/fim_system_tampering_rules.xml`; the deployed file is `/var/ossec/etc/rules/fim_system_tampering_rules.xml` on the Manager. Rule IDs are reserved for Project 03 (`100030–100037`). Rule `100034` correlates sensitive events by `audit_uid` in a 300-second window. Where correlation changes the final alert, individual rules are validated in isolated test runs.

## 5. Who-data

The recorded configuration uses the audit provider, `restart_audit=yes` and `startup_healthcheck=yes`. Who-data may distinguish the login identity from the effective process identity. For example, an administrator logged in as `aralrez` (UID 1000) may perform a command through `sudo`, while the effective audit user is root (UID 0). Reports must preserve that distinction and include only fields present in the alert.

## 6. Response layer

There is no Project 03 Active Response command for quarantine. An analyst reviews the Manager alert and may manually invoke `/usr/local/sbin/wazuh-project03-quarantine` on the Agent. The utility is limited to regular files directly below `/opt/wazuh-fim-lab/watch`.

The quarantine directory is root-only (`0700`), the audit log is root-only (`0600`), and the repository/deployed utility hash was compared on 2026-11-19. See `response-policy.md`.

## 7. Trust boundaries

- Wazuh Agent collects events; Manager performs central rule analysis.
- Dashboard is a view of alerts, not the response authority.
- The manual quarantine tool is a separate privileged program; do not invoke it from Wazuh Active Response.
- The test watch path is not a production incident-response target.
