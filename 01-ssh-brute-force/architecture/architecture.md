# Architecture — SSH Brute Force Detection & Active Response

## Objective
Detect SSH brute-force attacks, correlate successful logins after brute force, and automatically block the attacker IP using Wazuh Active Response.

## Lab Topology

```text
Kali (Attacker)
192.168.122.112
        |
        | SSH brute-force (Hydra)
        v
Ubuntu Agent (Victim)          Fedora (Trusted)
192.168.122.149                192.168.122.1
Wazuh Agent                    (whitelist)
        |
        | events
        v
Wazuh Manager (my-server)
192.168.122.178
Rules + Active Response
