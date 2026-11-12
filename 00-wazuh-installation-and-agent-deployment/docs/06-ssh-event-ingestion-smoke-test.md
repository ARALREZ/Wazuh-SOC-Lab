# SSH Event Ingestion Smoke Test

## Objective

Verify that SSH authentication telemetry from `my-agent` is collected
by the Wazuh Agent, forwarded to the Manager and visible in Wazuh data.

This procedure validates platform telemetry ingestion only.

## Safety and scope

Run this test only inside the isolated SOC lab and only against `my-agent` (`192.168.122.208`). Do not target public IP addresses or third-party systems. Use a dedicated, non-privileged test account. Never put passwords in shell history, scripts, screenshots, or Git.

## Preconditions

On `my-agent`:

```bash
sudo systemctl is-active ssh
sudo systemctl is-active wazuh-agent
sudo journalctl -u ssh --since '10 minutes ago' --no-pager | tail -n 30
```

The agent log from the current deployment confirms that it monitors journal entries. The SSH service must be active and the test events must appear in the local SSH journal before troubleshooting Wazuh ingestion.

## Generate a small controlled set of failures

From the Fedora workstation or another lab host, use the dedicated test account and enter an intentionally incorrect password for a small number of attempts:

```bash
ssh -o PreferredAuthentications=password \\
    -o PubkeyAuthentication=no \\
    -o NumberOfPasswordPrompts=1 \\
    soc-test@192.168.122.208
```

Repeat manually up to five times, allowing the connection attempt to finish each time. Do not automate high-volume attempts. If password authentication is disabled by the lab's SSH policy, do not weaken production settings; use a controlled test configuration or stop and document the limitation.

## Verify local source events

On `my-agent`:

```bash
sudo journalctl -u ssh --since '10 minutes ago' --no-pager \\
  | grep -Ei 'Failed password|authentication failure|Invalid user'
```

If no matching event appears locally, fix the SSH test or inspect the correct SSH logging source before investigating Wazuh.

## Verify Wazuh ingestion

On `my-server`:

```bash
sudo grep -Ei 'sshd|authentication failed|invalid user|failed password' \\
  /var/ossec/logs/alerts/alerts.json | tail -n 30
```

In the Dashboard, filter alerts for agent `my-agent` and SSH/authentication-related rule groups. Field names and rule IDs may vary by release and event type; validate the actual event fields rather than assuming a single rule ID.

## Optional successful-login control

After the failed-login test, perform one authorized successful login using the dedicated test account. Confirm that the corresponding successful authentication event is visible in the local journal and, where enabled by the configured rules, in Wazuh alerts.

## Pass criteria

- Failed SSH authentication events are present in the `my-agent` journal.
- Corresponding SSH/authentication events are present in Wazuh alert data and can be attributed to `my-agent`.
- No unrelated host is targeted.
- Sanitized evidence is saved under `evidence/`.

## Scope boundary

This is a Project 00 infrastructure smoke test.

It does not validate the six custom Project 01 detection rules,
correlation logic, password spraying, brute-force thresholds or
Active Response enforcement.

Detailed SSH scenario detection and response testing belongs to
[Project 01](../../01-ssh-brute-force/README.md).

A visible SSH event or default Wazuh alert is sufficient for the
ingestion objective. Do not interpret this procedure as proof that
a custom detection rule or firewall block works.
