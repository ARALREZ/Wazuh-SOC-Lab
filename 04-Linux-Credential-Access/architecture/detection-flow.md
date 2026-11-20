# Project 04 — Detection Flow

```text
Kali (192.168.122.112)
  |
  | SSH login as p04-labuser
  v
my-agent (192.168.122.208) — Ubuntu / Auditd / Wazuh Agent 001
  |
  | denied access to /etc/shadow
  | Auditd event: key=shadow_access, success=no, auid=1008
  v
/var/log/audit/audit.log
  |
  | one Wazuh localfile reader (log_format=audit)
  v
Wazuh Manager (192.168.122.178)
  |
  +--> 100040 / level 7 — one denied attempt
  +--> 100041 / level 10 — three attempts for same audit.auid in 90s
  +--> 100042 / level 12 — critical sequence for same audit.auid in 120s
         |
         | Active Response planned only for 100042
         v
my-agent — p04-lock-test-account.sh
  |
  +--> verify command=add and rule.id=100042
  +--> verify alert audit.auid == UID(p04-labuser)
  +--> passwd -l p04-labuser
  +--> log decision to active-responses.log
```

## Important interpretation

The test source IP is useful for describing the SSH connection, but the detection and response are based on local Auditd identity (`audit.auid`), not source-IP blocking. A different AUID must not be combined into one correlation bucket and must not trigger the account lock.

The response stage remains disabled until the live detection-only stage proves the real audit event and Manager alert. `wazuh-logtest` is not live telemetry evidence.
