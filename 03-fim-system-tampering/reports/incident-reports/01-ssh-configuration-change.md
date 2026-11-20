# Lab Incident 01 — SSH Configuration Change

**Classification:** Security-relevant configuration change (lab simulation)  
**Primary rule:** `100031`, level 10  
**Endpoint:** `my-agent`, Agent `001`  
**Status:** Detection test confirmed by operator; enrich exact event fields from the saved alert before external publication.

## Executive summary

A controlled change to a temporary SSH configuration file under `/etc/ssh/sshd_config.d` generated a Project 03 sensitive-configuration alert. The test demonstrates detection of a change to SSH authentication policy; it does not prove that an attacker obtained access or that the SSH service was successfully reconfigured.

## Evidence to attach

- `evidence/100031_ssh_config_change.png`
- Matching sanitized Manager alert JSON from `evidence/alerts/`
- Who-data fields if present in that alert

## Investigation record

| Field | Value |
|---|---|
| Host | `my-agent` |
| Agent ID | `001` |
| Rule | `100031` / level 10 |
| Affected path | Exact path must be copied from the alert JSON |
| Event timestamp | Exact value must be copied from the alert JSON |
| Actor / process | Record only actual Who-data fields |
| Test type | Controlled lab configuration change |

## Analyst assessment

The alert indicates a monitored SSH configuration file changed. The analyst should compare the file with the approved baseline, determine whether the change was authorized and check related authentication events. Do not infer a successful login or persistence solely from this FIM alert.

## Response

No automatic quarantine is performed. The SSH configuration path is outside the lab watch allow-list and must not be passed to the lab quarantine utility.

## Closure

Close after confirming the test change was reverted or intentionally retained, the evidence is saved and no unexpected authentication impact remains. Insert actual restoration evidence and timestamp before calling the case closed.
