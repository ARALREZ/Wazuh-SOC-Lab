# Architecture - Scenario 03: File Integrity Monitoring

## Lab Components

| Role              | Host            | IP               | Description                          |
|-------------------|-----------------|------------------|--------------------------------------|
| SIEM / XDR        | my-server       | 192.168.122.178  | Wazuh Manager 4.x                    |
| Victim / Agent    | Ubunru-Agent    | 192.168.122.149  | Ubuntu + Wazuh Agent + FIM           |
| Attacker          | local / Kali    | -                | Simulates file tampering             |

## Event Flow

```text
Attacker modifies critical file (/etc/passwd, /etc/hosts, etc.)
│
▼
Wazuh Agent (syscheck - realtime)
│
│  syscheck event (550/554)
▼
Wazuh Manager
│
├── Rule 100030 (Soft)
├── Rule 100031 (Medium - critical file)
├── Rule 100032 (Critical) ──► Active Response (quarantine-file.sh)
└── Rule 100033 (Layered)
│
▼
Wazuh Dashboard / alerts.json
```



## Active Response Flow
```text
1. Rule 100032 or 100033 matches
2. Manager sends Active Response command to the agent
3. Agent executes `/var/ossec/active-response/bin/quarantine-file.sh`
4. Script:
   - Sets permissions to 000
   - Sets immutable attribute (`chattr +i`)
   - Moves file to `/var/ossec/quarantine/`
```
