# Project 04 — Architecture

## Purpose

Detect denied attempts to access `/etc/shadow` on `my-agent` and, only after independent live validation, lock password authentication for the dedicated account `p04-labuser` when the critical rule `100042` is generated.

## Components

| Component | Host | Responsibility |
|---|---|---|
| Auditd | `my-agent` | Records relevant syscalls against `/etc/shadow` with key `shadow_access`. |
| Wazuh Agent 001 | `my-agent` | Reads `/var/log/audit/audit.log` once and forwards events. |
| Wazuh Manager | `my-server` | Decodes Auditd fields, evaluates custom rules and emits alerts. |
| Active Response | `my-agent` via `location=local` | Planned password lock for `p04-labuser`, only on rule `100042` and matching `audit.auid`. |
| Kali | `192.168.122.112` | Authorized SSH source for live tests. |
| Fedora | Admin workstation | Holds the repository and runs deployment/verification commands. |

## Detection rules

- `100040`, level 7: a denied event with `audit.key=shadow_access` and `audit.success=no`.
- `100041`, level 10: repeated matches for the same `audit.auid` in 90 seconds.
- `100042`, level 12: critical correlation for the same `audit.auid` in 120 seconds.

For the current Wazuh 4.14.10 lab run, `100042` is configured with `frequency="4"` because `100041` classifies the third event. The synthetic regression then produced `100042` on the fifth event. This behavior still requires live confirmation.

## Security boundaries

- The rule file is separate from Projects 01–03 and does not use `local_rules.xml`.
- Project 04 does not modify existing `firewall-drop` blocks.
- No IP block or iptables rule is part of this scenario.
- Active Response is not yet deployed or enabled in the current snapshot.
- The response target is a hard-coded allow-listed user, `p04-labuser`; the script additionally checks alert AUID against its actual UID.
- `passwd -l` affects password authentication only. It does not terminate an existing shell or guarantee denial of SSH public-key authentication.

## Platform baseline

Wazuh Manager and Agent `4.14.10-1`, Ubuntu 24.04.5 LTS on Manager and Agent. Project 00 owns installation and enrollment evidence; Project 04 records only scenario-specific changes and tests.
