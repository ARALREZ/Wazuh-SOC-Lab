# Lab Incident 02 — SSH Authorized Keys Modification

**Classification:** SSH persistence / account authorization change (lab simulation)  
**Primary rule:** `100032`, level 12  
**MITRE ATT&CK:** `T1098.004` — SSH Authorized Keys  
**Endpoint:** `my-agent`, Agent `001`

## Executive summary

A controlled modification of `/home/aralrez/.ssh/authorized_keys` generated a Project 03 alert. The test validates that FIM can detect a change to an SSH authorization file. It does not establish that a new key was used to authenticate or that an account was compromised.

## Evidence

- `evidence/100032-authorized-keys-change-agent.png`
- Matching sanitized alert from `evidence/alerts/`
- Matching Who-data record from `evidence/whodata/`, if present

The historical test state recorded the file as empty, owned by `aralrez:aralrez`, mode `0600`, with the SHA256 of an empty file. Do not copy private or public key contents into this report.

## Investigation record

| Field | Value |
|---|---|
| Host / Agent | `my-agent` / `001` |
| Rule | `100032`, level 12 |
| File | `/home/aralrez/.ssh/authorized_keys` |
| Login identity | Use `login_user.name` / `login_user.id` from the actual event |
| Effective identity | Use `audit.user.id` if present; do not assume it equals login UID |
| Process / parent | Copy only fields present in the actual event |
| Timestamp | Copy from the actual alert |

## Analyst assessment

An unexpected change to `authorized_keys` can add or remove an SSH authentication method. Compare the file with the approved key inventory and review adjacent SSH authentication events. The FIM alert alone does not establish that the changed key was used.

## Response and closure

The test was a controlled lab change. Verify the expected authorized-keys state and access before closing. Do not use the Project 03 lab quarantine tool on this SSH file; the utility is restricted to `/opt/wazuh-fim-lab/watch` and is not an Active Response action.
