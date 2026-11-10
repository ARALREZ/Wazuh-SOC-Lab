# Agent Enrollment and Connection Validation

## Enrollment result

The Manager log recorded:

```text
Received request for a new agent (my-agent) from: 192.168.122.208
Agent key generated for 'my-agent' (requested by any)
```

The Manager agent list then showed:

```text
ID: 001, Name: my-agent, IP: any, Active
```

The `agent_control -lc` output also listed agent `001` as `Active`. This confirms the agent is enrolled and connected at the time of the captured check.

## Validate on the Manager

Run on `my-server`:

```bash
sudo /var/ossec/bin/agent_control -l
sudo /var/ossec/bin/agent_control -lc
sudo grep -E 'Received request for a new agent|Agent key generated' \\
  /var/ossec/logs/ossec.log | tail -n 20
```

## Validate on the endpoint

Run on `my-agent`:

```bash
sudo systemctl is-active wazuh-agent
sudo systemctl is-enabled wazuh-agent
sudo grep -nE '<address>|<port>|<protocol>' /var/ossec/etc/ossec.conf
sudo test -s /var/ossec/etc/client.keys && echo 'Enrollment key file exists'
sudo tail -n 40 /var/ossec/logs/ossec.log
```

Do not display `/var/ossec/etc/client.keys`; it contains the agent authentication key.

## Current status

Enrollment is complete. Proceed to version pinning and the controlled SSH/FIM validation tasks.
