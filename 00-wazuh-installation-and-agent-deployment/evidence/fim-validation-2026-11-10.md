
# FIM Validation Evidence

## Test information

| Field | Value |
|---|---|
| Test date | 2026-11-10 |
| Agent | my-agent |
| Agent ID | 001 |
| Manager | my-server |
| Wazuh version | 4.14.10 |
| Monitoring mode | Real-time |
| Test directory | `/var/tmp/wazuh-fim-lab` |
| Result | PASS - Manager alert generation |

## Observed events

All three expected FIM events were found in:

`/var/ossec/logs/alerts/alerts.json`

| Timestamp (UTC) | Rule ID | Level | Detection |
|---|---:|---:|---|
| 22:51:36.578 | 554 | 5 | File added to the system |
| 22:51:41.603 | 550 | 7 | Integrity checksum changed |
| 22:51:46.589 | 553 | 7 | File deleted |

## Integrity verification

The modification event reported the following changed attributes:

- File size.
- Modification time.
- MD5 checksum.
- SHA1 checksum.
- SHA256 checksum.

File size changed from 18 bytes to 36 bytes.

The SHA256 checksum changed from:

`4a2dad2b8ce68958a4e82cea1c91a2e05afd23c7a7780e7551dd2d6109b7c18e`

to:

`c5448a3b9f56c16fa58a56db90e0096f40d060c83405a11f6b2b6446c157689d`

## Monitoring verification

The agent log contained:

- `(6016): Directory set for real time monitoring`
- `(6012): Real-time file integrity monitoring started`

The agent service returned `active`.

## Dashboard verification

Status: NOT VERIFIED IN THE CAPTURED EVIDENCE.

Manager-side alert generation is confirmed. Dashboard visibility must be checked separately before claiming full end-to-end validation.

## Cleanup

Cleanup completed on 2026-11-11.

- Test file: deleted.
- Test directory: removed.
- Temporary syscheck configuration: removed.
- Wazuh Agent: restarted successfully.
- Agent service status: active.

## Conclusion

Wazuh successfully detected file creation, modification, and deletion in the configured real-time monitoring directory.

The modification alert included changes to file metadata and cryptographic checksums.

Manager-side FIM alert generation: PASS.
