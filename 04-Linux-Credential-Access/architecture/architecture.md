# Architecture - Scenario 04: Linux Credential Access

## Lab Topology

```text
Attacker (local user / Kali)
        |
        | tries to read /etc/shadow
        v
Agent (Ubuntu + auditd + Wazuh Agent)
        |
        | auditd event (key=shadow_access)
        v
Wazuh Manager
        |
        +--> Rule 100040 (soft)
        +--> Rule 100041 (medium, frequency)
        +--> Rule 100042 (critical) --> Active Response
                                        |
                                        v
                                 block-attacker.sh
                                 - passwd -l (account lock)
