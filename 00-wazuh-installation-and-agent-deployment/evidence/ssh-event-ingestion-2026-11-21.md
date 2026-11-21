# SSH Event-Ingestion Evidence — 2026-11-21

## Test metadata

| Field | Value |
|---|---|
| Test run ID | `p00-ssh-ingestion-20261121T195001Z` |
| Test date | 2026-11-21 |
| Time basis | Manager alert timestamps in UTC; Agent journal in Europe/Warsaw local time |
| Wazuh version | 4.14.10 |
| Source | Kali, `192.168.122.112` |
| Target | `my-agent`, `192.168.122.208` |
| Agent ID | `001` |
| Manager | `my-server`, `192.168.122.178` |
| SSH logging source | journald |
| Test type | One controlled failed authentication attempt using a deliberately nonexistent username |
| Result | PASS — source event observed locally and in Manager alert data |

## Client result

The Kali client confirmed address `192.168.122.112/24`. One SSH attempt was made with:

```bash
ssh -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o NumberOfPasswordPrompts=1 \
    -o ConnectTimeout=5 \
    p00-smoke-invalid@192.168.122.208
```

The SSH client ended with:

```text
Permission denied (publickey,password).
```

No account credential is included in this evidence.

## Agent-side source events

The Agent journal showed the following events for the same SSH connection:

| Agent local time (UTC+01:00) | Event |
|---|---|
| 2026-11-21 20:50:01 | Invalid user `p00-smoke-invalid` from `192.168.122.112` |
| 2026-11-21 20:50:05 | PAM authentication failure from `192.168.122.112` |
| 2026-11-21 20:50:07 | Failed password for invalid user `p00-smoke-invalid` |
| 2026-11-21 20:50:08 | Connection closed by invalid user during pre-authentication |

## Manager-side alert events

Manager `/var/ossec/logs/alerts/alerts.json` contained the corresponding events:

| Manager timestamp (UTC) | Rule ID | Description | Source |
|---|---:|---|---|
| 2026-11-21 19:50:01.526 | 5710 | sshd: Attempt to login using a non-existent user | journald |
| 2026-11-21 19:50:05.518 | 5503 | PAM: User login failed. | journald |
| 2026-11-21 19:50:07.520 | 5710 | sshd: Attempt to login using a non-existent user | journald |

The alerts identified Agent ID `001`, Agent name `my-agent`, source IP `192.168.122.112` and Manager `my-server`. The `5710` event was recorded twice for different sshd messages in the same connection; this is not evidence of two separate SSH attempts.

The Agent journal timestamps are one hour ahead of the Manager UTC timestamps, as expected for the local timezone at the time of the test.

## Conclusion and limits

**PASS:** SSH authentication telemetry was present in the Agent journal and was processed into Manager alert data. The observed records used the `journald` location.

This confirms Project 00 event ingestion only. The test did not validate custom Project 01 rules, brute-force thresholds, correlation, firewall blocking or Active Response.

No password, agent key, private key or credential material is included.
