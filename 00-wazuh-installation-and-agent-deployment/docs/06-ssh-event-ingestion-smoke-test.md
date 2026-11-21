# SSH Event Ingestion Smoke Test

## Objective

Verify that SSH authentication telemetry from `my-agent` is collected by the Wazuh Agent, forwarded to the Manager and visible in Manager alert data.

This procedure validates platform telemetry ingestion only. It is not a Project 01 brute-force regression or Active Response test.

## Safety and scope

Run this test only inside the isolated SOC lab and only against `my-agent` (`192.168.122.208`). Use Kali (`192.168.122.112`) or another authorized lab client. Do not target public IP addresses or third-party systems.

Use exactly one controlled SSH attempt per smoke-test run. Use a deliberately nonexistent username so no real account is targeted. Never enter a real account password, and never put passwords in shell history, scripts, screenshots or Git. Do not repeat the attempt as a way to test brute-force thresholds; those tests belong to Project 01.

## Preconditions

On `my-agent`:

```bash
sudo systemctl is-active ssh
sudo systemctl is-active wazuh-agent
sudo journalctl -u ssh --since '10 minutes ago' --no-pager | tail -n 30
```

The SSH service and Wazuh Agent must be active. The test event must first appear in the local SSH journal.

On Kali, confirm the expected lab source address:

```bash
date -Is
ip -br addr
```

## Generate one controlled failure

From Kali, run the following command once. When prompted, do not supply a real account credential.

```bash
ssh -o PreferredAuthentications=password \
    -o PubkeyAuthentication=no \
    -o NumberOfPasswordPrompts=1 \
    -o ConnectTimeout=5 \
    p00-smoke-invalid@192.168.122.208
```

The deliberately nonexistent username is `p00-smoke-invalid`. A rejected login is expected. Do not alter SSH server authentication policy to make this test pass.

## Verify local source events

On `my-agent`:

```bash
sudo journalctl -u ssh --since '5 minutes ago' --no-pager \
  | grep -Ei 'Failed password|authentication failure|Invalid user'
```

If no matching event appears locally, stop and inspect the SSH service and logging source before troubleshooting Wazuh.

## Verify Wazuh ingestion

On `my-server`, search using the source address and test username:

```bash
sudo grep -aEi \
  '192\.168\.122\.112|p00-smoke-invalid' \
  /var/ossec/logs/alerts/alerts.json | tail -n 10
```

Confirm that the alert records identify Agent `001` / `my-agent`, the expected source address and SSH/PAM authentication events.

On Wazuh `4.14.10`, the 2026-11-21 baseline run observed built-in rule IDs `5710` (non-existent SSH user / failed password) and `5503` (PAM authentication failure). Rule IDs and descriptions can vary by release and event type; inspect the actual alert rather than assuming these IDs are universal.

One SSH connection can produce multiple journal messages and alert records (for example, invalid user, PAM authentication failure and failed password). Do not count each record as a separate login attempt.

## Pass criteria

- One controlled failed SSH attempt is generated from an authorized lab client.
- The event is present in the local SSH journal on `my-agent`.
- Corresponding event data is present in Manager `alerts.json` and attributed to Agent `001`.
- Source and target addresses match the test topology.
- No unrelated host or real account is targeted.
- Sanitized evidence is recorded under `evidence/` and the result is summarized under `reports/`.

## Scope boundary

This is a Project 00 infrastructure smoke test. It does not validate custom Project 01 detection rules, brute-force or password-spraying thresholds, correlation logic or Active Response enforcement.

Detailed SSH scenario detection and response testing belongs to [Project 01](../../01-ssh-brute-force/README.md).

A visible SSH event or default Wazuh alert is sufficient for the Project 00 ingestion objective. Do not interpret this procedure as proof that a custom detection rule or firewall block works.
