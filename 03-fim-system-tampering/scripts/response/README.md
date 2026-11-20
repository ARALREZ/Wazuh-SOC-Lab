# Manual Quarantine Utility

## Purpose

`quarantine-file.sh` is the source for deployed `/usr/local/sbin/wazuh-project03-quarantine`. It is manually invoked by an administrator and is not a Wazuh Active Response script.

## Paths

- Allowed source root: `/opt/wazuh-fim-lab/watch`
- Quarantine root: `/var/lib/wazuh-project03/quarantine`
- Audit log: `/var/log/wazuh-project03-quarantine.log`

## Commands

```bash
sudo /usr/local/sbin/wazuh-project03-quarantine init
sudo /usr/local/sbin/wazuh-project03-quarantine quarantine \
  /opt/wazuh-fim-lab/watch/EXAMPLE.txt
sudo /usr/local/sbin/wazuh-project03-quarantine restore \
  /var/lib/wazuh-project03/quarantine/ITEM_NAME
```

Use only the exact item path returned by the command. The script rejects paths outside the watch root, traversal, symlinks, hardlinks and special files. Restore refuses overwrite. A failed restore must not be followed by manual deletion of the payload.

## Integrity

The utility records SHA256 and metadata in a root-owned manifest. It logs `quarantine` and `restore` actions as JSONL. The tested implementation preserves inode and tested ACL/user-xattr examples in the recorded ext4 lab setup. Do not generalize this to every filesystem or xattr namespace.

## Verification

The recorded 2026-11-19 deployed/repository SHA256 was:

`fc53c7f50ce330d2415ec91d43b7832da78ec06721ab1b27b499181b21a37a1b`

Recalculate the hash after any source update and compare it with the deployed copy before calling the versions identical.
