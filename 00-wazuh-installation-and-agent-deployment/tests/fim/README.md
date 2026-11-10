
# File Integrity Monitoring Tests

See the [FIM validation procedure](../../docs/07-file-integrity-monitoring-validation.md).

## Test scope

Dedicated monitoring directory:

`/var/tmp/wazuh-fim-lab`

The test validates:

1. File creation.
2. File modification.
3. File deletion.
4. Integrity checksum changes.

## Expected detections

| Operation | Wazuh Rule ID | Expected result |
|---|---:|---|
| Creation | 554 | File added alert |
| Modification | 550 | Integrity checksum changed |
| Deletion | 553 | File deleted alert |

## Evidence

Record:

- Test date and timezone.
- Agent name and ID.
- Monitored file path.
- Alert timestamps.
- Rule IDs and severity levels.
- Observed integrity changes.
- Dashboard verification status.
- Cleanup status.

See `../../evidence/fim-validation-2026-11-10.md`.

Never include passwords, agent keys, private certificates, or unrelated system logs.
