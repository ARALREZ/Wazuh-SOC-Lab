
# File Integrity Monitoring (FIM) Validation

## Objective

Validate real-time File Integrity Monitoring on the Ubuntu endpoint using Wazuh Syscheck.

The test covers:

1. File creation.
2. File modification.
3. File deletion.
4. Integrity checksum changes.
5. Alert generation on the Wazuh Manager.

## Lab environment

| Component | Value |
|---|---|
| Manager | my-server |
| Agent | my-agent |
| Agent ID | 001 |
| Wazuh version | 4.14.10 |
| Monitored directory | `/var/tmp/wazuh-fim-lab` |
| Monitoring mode | Real-time |

## Preconditions

On `my-agent`:

```bash
sudo systemctl is-active wazuh-agent

sudo grep -n -A35 -B3 '<syscheck>' \
  /var/ossec/etc/ossec.conf
```

Confirm that the test directory does not already have an unintended monitoring configuration.

Do not create a second `<syscheck>` section.

## Configure the test directory

Create the directory before restarting the agent:

```bash
sudo install -d -m 0755 /var/tmp/wazuh-fim-lab
```

Back up the existing configuration:

```bash
sudo cp -a /var/ossec/etc/ossec.conf \
  "/var/ossec/etc/ossec.conf.bak.$(date +%F-%H%M%S)"
```

Add the following entry inside the existing `<syscheck>` section:

```xml
<directories check_all="yes" realtime="yes">/var/tmp/wazuh-fim-lab</directories>
```

Restart the agent:

```bash
sudo systemctl restart wazuh-agent

sudo systemctl is-active wazuh-agent
```

Verify real-time monitoring:

```bash
sudo grep -Ei 'real.time|syscheck|error|invalid' \
  /var/ossec/logs/ossec.log | tail -n 20
```

Expected messages include:

- Directory set for real-time monitoring.
- Real-time file integrity monitoring started.

## Perform controlled file operations

Create the test file:

```bash
echo "FIM test baseline" | sudo tee \
  /var/tmp/wazuh-fim-lab/fim-test.txt
```

Wait five seconds and modify it:

```bash
sleep 5

echo "FIM test modified" | sudo tee -a \
  /var/tmp/wazuh-fim-lab/fim-test.txt
```

Wait five seconds and delete it:

```bash
sleep 5

sudo rm /var/tmp/wazuh-fim-lab/fim-test.txt
```

Wait for alert generation:

```bash
sleep 5
```

## Verify alerts on the Wazuh Manager

Run on `my-server`:

```bash
sudo grep -F \
  '/var/tmp/wazuh-fim-lab/fim-test.txt' \
  /var/ossec/logs/alerts/alerts.json | tail -n 10
```

Expected detections:

| Operation | Rule ID | Level |
|---|---:|---:|
| File added | 554 | 5 |
| Integrity checksum changed | 550 | 7 |
| File deleted | 553 | 7 |

## Dashboard verification

In the Wazuh Dashboard:

1. Filter events for agent `my-agent`.
2. Search for `/var/tmp/wazuh-fim-lab/fim-test.txt`.
3. Confirm the creation, modification, and deletion alerts.

Record Dashboard verification separately from Manager-side alert generation.

## Cleanup

After collecting evidence, remove the test directory entry from the existing `<syscheck>` section.

Back up the configuration before editing it.

Restart the agent:

```bash
sudo systemctl restart wazuh-agent
sudo systemctl is-active wazuh-agent
```

Remove the empty test directory:

```bash
sudo rmdir /var/tmp/wazuh-fim-lab
```

## Pass criteria

- Agent remains active after the configuration change.
- Real-time FIM monitoring starts successfully.
- File creation produces a FIM alert.
- File modification produces an integrity checksum alert.
- File deletion produces a FIM alert.
- Events are attributed to `my-agent`.
- Dashboard visibility is separately verified and documented.
- Temporary monitoring configuration and test files are removed after validation.

## Evidence

See:

`../../evidence/fim-validation-2026-11-10.md`
