# Response Policy — Manual Quarantine

## 1. Policy statement

Project 03 uses **manual, administrator-approved, reversible quarantine**. Wazuh raises an alert; an administrator reviews it and independently decides whether to invoke the quarantine utility. No Project 03 FIM rule is configured to execute this utility through Active Response.

## 2. Why response is manual

Automatic movement of arbitrary system files can disrupt authentication, scheduled tasks, services or system boot. The current utility is intentionally restricted to the dedicated test directory so response behavior can be demonstrated without moving live operating-system files.

## 3. Allowed scope

- Source root: `/opt/wazuh-fim-lab/watch`
- Allowed object: existing regular file directly inside the source root
- Quarantine store: `/var/lib/wazuh-project03/quarantine`
- Audit log: `/var/log/wazuh-project03-quarantine.log`
- Utility: `/usr/local/sbin/wazuh-project03-quarantine`

The tool refuses outside paths, non-canonical paths/traversal, symlinks, hardlinks, FIFOs and special files. Restore refuses to overwrite an existing destination.

## 4. Operator workflow

1. Read the Manager alert and confirm the affected path and host.
2. Review Who-data fields if present. Keep login identity separate from effective UID.
3. Confirm that the path is directly inside the lab watch directory.
4. Record the alert ID, timestamp and reason for the action.
5. Quarantine only the approved test file.
6. Verify source absence, quarantine payload, SHA256 and metadata.
7. Retain the JSONL audit record.
8. Restore after the demonstration/investigation and verify SHA256 and metadata.

Example commands (lab watch only):

```bash
sudo /usr/local/sbin/wazuh-project03-quarantine init
sudo /usr/local/sbin/wazuh-project03-quarantine quarantine \
  /opt/wazuh-fim-lab/watch/TEST-FILE.txt
sudo /usr/local/sbin/wazuh-project03-quarantine restore \
  /var/lib/wazuh-project03/quarantine/ITEM_NAME
```

Use the actual item path printed by the command. Do not replace it with a guessed value.

## 5. Prohibited integration

- Do not add an `<active-response>` block for the quarantine utility.
- Do not attach `firewall-drop` to FIM rules `100031–100037`.
- Do not quarantine `/etc/passwd`, `/etc/shadow`, SSH configuration, cron/systemd files or other production paths with this lab utility.
- Do not clear the quarantine directory as a cleanup shortcut.

## 6. Recovery and audit

The utility uses same-filesystem atomic rename in the recorded ext4 lab environment. The payload is accompanied by a manifest; the JSONL log records timestamp, action, original path, SHA256 and quarantine item. Preserve any payload if a restore fails. Resolve the conflict or investigate manually; do not delete the payload.

## 7. Known limitations

A dedicated audit-log write-failure fault-injection test and a concurrency/race test have not been completed. Atomic rename reduces the copy/delete window but does not prove the absence of every race condition. ACL and user xattr preservation were tested on concrete ext4 examples, not every possible xattr namespace or filesystem.
