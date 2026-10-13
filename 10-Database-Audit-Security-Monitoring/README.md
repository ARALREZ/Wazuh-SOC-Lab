# Scenario 10: PostgreSQL 16 Audit Security Monitoring & Active Response (SOAR)

## 📌 Executive Summary
This project implements an end-to-end security monitoring, real-time auditing, and automated threat containment pipeline for PostgreSQL 16 on Ubuntu endpoints. By integrating the `pgaudit` extension, database session and object queries are redirected to standard error (`stderr`), monitored via Wazuh Logcollector, decoded using custom decoders, and evaluated against strict SIEM detection rules. Malicious activities such as unauthorized data access (`SELECT`) and schema/privilege modifications (`DDL`) trigger custom high-severity alerts mapped to the MITRE ATT&CK framework, accompanied by an automated Active Response script that isolates attacking hosts using `iptables` while preserving SIEM agent connectivity.

## 📐 Network & Lab Architecture
* **SIEM / XDR Manager:** Wazuh Manager 4.x (`moj-server`) deployed via Docker/Native packages.
* **Target Endpoint (Victim / Database):** PostgreSQL 16 on Ubuntu + Wazuh Agent (`aralrez-Victus-HP` / `moj_agent`).
* **Attacker Host:** Kali Linux (Remote `psql` session for threat simulation).

## 🔍 MITRE ATT&CK Mapping
* **Tactic:** Collection (TA0009) / Impact (TA0040)
* **Technique:** Data from Information Repositories (T1213)
* **Technique:** Data Destruction / Schema Modification (T1485)

## ⚙️ Custom Detection Rules & Active Response

### 1. PostgreSQL & Audit Logging Configuration (`/etc/postgresql/16/main/postgresql.conf`)
Configured to capture comprehensive session and object activity and output cleanly to `stderr`:
```text
logging_collector = on
log_destination = 'stderr'
pgaudit.log = 'read, write, ddl, session'
```
###2. Wazuh Custom Decoder (configs/local_decoder.xml)

Deployed on the Wazuh Manager to parse incoming PostgreSQL audit log streams:
```xml
<decoder name="postgresql-audit">
  <prematch>AUDIT: SESSION</prematch>
</decoder>
```

###3. Custom SIEM Detection Rules (rules/database_rules.xml)

Rules defined on the Wazuh Manager for baseline event recording, SELECT data access, and DDL modifications:
```xml
<group name="postgresql,database,security">  
  <!-- Catch-all base rule for PostgreSQL audit logs -->
  <rule id="100102" level="3">
    <decoded_as>postgresql-audit</decoded_as>
    <description>PostgreSQL: Audit event recorded.</description>
  </rule>

  <!-- Rule to detect potential DDL / Schema Modification or Privilege Abuse -->
  <rule id="100100" level="10">
    <if_sid>100102</if_sid>
    <match>DDL</match>
    <description>PostgreSQL: Potential DDL / Schema Modification detected.</description>
    <mitre>
      <id>T1485</id>
      <id>T1078</id>
    </mitre>
  </rule>

  <!-- Rule to detect data access (SELECT) on database objects -->
  <rule id="100101" level="6">
    <if_sid>100102</if_sid>
    <match>SELECT</match>
    <description>PostgreSQL: Data Access (SELECT) query executed on database table.</description>
    <mitre>
      <id>T1213</id>
    </mitre>
  </rule>
</group>
```

###4. Agent Log Monitoring & Active Response Bindings (configs/ossec.conf.add)

Configured on the Wazuh Agent (aralrez-Victus-HP) and Manager:
```xml
<!-- Wazuh Agent configuration to monitor PostgreSQL audit logs -->
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/lib/postgresql/16/main/log/*.log</location>
  </localfile>
</ossec_config>

<!-- Active Response Command Definition on Manager -->
<command>
  <name>block-attacker</name>
  <executable>block_attacker_ip.sh</executable>
  <expect>srcip</expect>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <command>block-attacker</command>
  <location>local</location>
  <rules_id>100100</rules_id>
  <timeout>60</timeout>
</active-response>
```

###5. SOAR Active Response Script (scripts/block_attacker_ip.sh)

Deployed on the target endpoint at /var/ossec/active-response/bin/block_attacker_ip.sh:
```xml
#!/bin/bash
# Wazuh Active Response Script: Block Attacker IP via iptables
# Leaves Wazuh agent connectivity unaffected (outbound TCP to manager).

ACTION=$1
USER=$2
IP=$3

LOG_FILE="/var/ossec/logs/active-responses.log"

if [ -z "$IP" ]; then
    echo "$(date): Error: No IP address provided to active response script." >> "$LOG_FILE"
    exit 1
fi

if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "$(date): Error: Invalid IP format: $IP" >> "$LOG_FILE"
    exit 1
fi

case "$ACTION" in
    add)
        iptables -A INPUT -s "$IP" -j DROP
        echo "$(date): SUCCESS: Blocked malicious IP $IP using iptables." >> "$LOG_FILE"
        ;;
    delete)
        iptables -D INPUT -s "$IP" -j DROP 2>/dev/null
        echo "$(date): SUCCESS: Unblocked IP $IP." >> "$LOG_FILE"
        ;;
    *)
        echo "$(date) data: Action $ACTION not implemented." >> "$LOG_FILE"
        exit 1
        ;;
esac

exit 0
```

###6. Attack & Simulation Commands (from Kali Linux)

Execute test queries from the remote attacker host to trigger both monitored events (SELECT and DDL):
```xml
psql -h <IP_AGENT> -U postgres -d test_soc_db -c "SELECT * FROM sensitive_data; CREATE TABLE soc_test_table (id int); DROP TABLE soc_test_table;"
```

###📂 Repository Structure Location Guide

Place your files inside the 10-Database-Audit-Security-Monitoring/ directory with the following layout:
```text
10-Database-Audit-Security-Monitoring/
├── README.md                      # Dokumentacja główna (którą już masz)
├── what_need                      # Cele i założenia
├── configs/
│   ├── agent_ossec.conf.add       # Co dodać do ossec.conf na Agencie (ścieżka do logów)
│   └── manager_ossec.conf.add     # Co dodać do ossec.conf na Managerze (Active Response)
├── decoders/
│   └── local_decoder.xml          # Dekodery logów PostgreSQL (ląduje na Managerze)
├── rules/
│   └── database_rules.xml         # Reguły DDL i SELECT (ląduje na Managerze)
└── scripts/
    └── block_attacker_ip.sh       # Skrypt blokujący IP (ląduje na Agencie)
