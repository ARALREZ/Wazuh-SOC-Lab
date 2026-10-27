# Architecture - Scenario 02: Web Attack Detection

## Lab Topology
```text
Kali (Attacker)
192.168.122.112
        |
        | HTTP attacks (SQLi / XSS / Path Traversal / Scanner)
        v
Ubuntu Agent (Victim)          Fedora (Trusted)
192.168.122.149                192.168.122.1
Wazuh Agent                    (whitelist)
        |
        | events/Apache access.log → Wazuh Agent
        v
Wazuh Manager (my-server)
192.168.122.178
+--> Custom rules 100020-100029
+--> Active Response (firewall-drop)
```

# Wazuh Dashboard / alerts.json

## Event Flow

1. Attacker sends malicious HTTP request
2. Apache writes entry to `/var/log/apache2/access.log`
3. Wazuh Agent reads the log (`log_format: apache`)
4. Manager decodes the event (base rule ~31100 / web group)
5. Custom rules 100020-100029 evaluate the event
6. High severity rules trigger Active Response → IP dropped on agent

## Key Components

| Component              | Role                                      |
|------------------------|-------------------------------------------|
| Apache2                | Generates access logs                     |
| Wazuh Agent            | Collects `/var/log/apache2/access.log`    |
| Custom rules           | Detection engineering (100020-100029)     |
| Active Response        | Automated containment (firewall-drop)     |
| Trusted IP (100028)    | Whitelist / noise reduction               |

## Detection Layers

- **Soft** (100020, 100029) – reconnaissance / suspicious patterns
- **Medium** (100021-100024) – specific attack techniques
- **Correlation** (100025, 100026) – multiple events from same IP
- **Layered** (100027) – attack after previous scanner activity
- **Whitelist** (100028) – trusted source
