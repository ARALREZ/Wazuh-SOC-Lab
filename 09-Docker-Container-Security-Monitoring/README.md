# Scenario 09: Docker Container Security Monitoring & Active Response (XDR)

## 📌 Executive Summary
This project demonstrates an automated XDR containment scenario designed to detect and isolate unauthorized or privileged Docker container deployments on Linux endpoints. Using Wazuh SIEM/XDR, custom correlation rules match container execution events captured by docker-listener, extract container metadata (ID and name), and invoke an active response Python script (docker_quarantine.py) to forcefully terminate (SIGKILL) and rename compromised containers for forensic auditing in real time.

## 📐 Network & Lab Architecture
SIEM / XDR Manager: Wazuh Manager 4.x (moj-server - Ubuntu Server)
Target Endpoint (Victim): Wazuh Agent (moj_agent / aralrez-Victus-HP - Kali/Ubuntu Laptop)
Attacker Account: Local unprivileged account (attacker)

## 🔍 MITRE ATT&CK Mapping
Tactic: Privilege Escalation (TA0004), Defense Evasion (TA0005), Execution (TA0002)
Technique: Escape to Host (T1611), Container Administration Command (T1609)

## ⚙️ Custom Detection Rules & Active Response
1. Custom Rules Configuration (rules/docker_rules.xml)
Analyzes Docker events captured by docker-listener (SIDs 87901, 87903) to detect malicious container names, docker.sock mounts, or privileged execution modes:

```xml
<group name="docker, container_security,">

  <!-- Custom Rule 100090: Unauthorized Container Name or Socket Mount -->
  <rule id="100090" level="12">
    <if_sid>87901,87903</if_sid>
    <regex>malicious_miner|docker\.sock</regex>
    <description>DevSecOps: Unauthorized container name or docker.sock mount detected.</description>
    <mitre>
      <id>T1611</id>
    </mitre>
  </rule>

  <!-- Custom Rule 100091: Privileged Execution Mode -->
  <rule id="100091" level="12">
    <if_sid>87901,87903</if_sid>
    <regex>privileged|Privileged</regex>
    <description>DevSecOps: Privileged container started (Privileged mode).</description>
    <mitre>
      <id>T1611</id>
    </mitre>
  </rule>

</group>
```

2. Active Response Configuration (configs/ossec.conf.snippet)
Configures docker-listener on the agent and binds Rules 100090 and 100091 to the quarantine Python script:

```xml
<!-- Agent Configuration (Docker Event Listener) -->
<wodle name="docker-listener">
  <interval>10m</interval>
  <attempts>5</attempts>
  <run_on_start>yes</run_on_start>
  <disabled>no</disabled>
</wodle>

<!-- Manager Configuration -->
<command>
  <name>docker-quarantine</name>
  <executable>docker_quarantine.py</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <command>docker-quarantine</command>
  <location>local</location>
  <rules_id>100090,100091</rules_id>
</active-response>
```


## 📁 Repository Structure
```text
09-Docker-Container-Security-Monitoring/
├── configs/
│   └── ossec.conf.snippet       # Docker wodle & Active Response binding config
├── docs/
│   └── screenshots/             # Dashboard evidence & containment logs
├── rules/
│   └── docker_rules.xml         # Custom detection rules 100090 & 100091
├── scripts/
│   └── docker_quarantine.py     # Python script executing container kill & rename
├── README.md                    # Scenario documentation README.md
└── what_do.txt                  # Quick testing and verification procedures
