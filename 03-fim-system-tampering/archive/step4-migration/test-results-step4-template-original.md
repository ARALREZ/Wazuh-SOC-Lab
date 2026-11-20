# Project 03 — Test results (manual quarantine and regression)

Date: 2026-11-17
Status: **In Progress — regression runner prepared; Agent/Manager automation run pending**

## Verified manual quarantine test (Agent)

Source run: `p03-quarantine-20261117T182828Z-4161`

| Test | Result | Observed evidence |
|---|---|---|
| Quarantine regular file | PASS | File stored under `/var/lib/wazuh-project03/quarantine/item.sbfdzrep` |
| SHA256 after quarantine | PASS | `f95447cb5f526c3fda10f7f7a9fbe698d992656a52b6691aa01573fb5b07f0db` |
| ACL preservation | PASS | ACL matched before/after quarantine and restore |
| Existing destination conflict | PASS | Restore refused; conflict file and quarantine payload remained intact |
| Restore | PASS | Original path recreated; SHA256 matched |
| POSIX metadata | PASS | Size, owner, group, permissions and mtime matched |
| ACL after restore | PASS | ACL matched original |
| Symlink source | PASS | Rejected |
| FIFO special file | PASS | Rejected |
| Hardlink | PASS | Rejected (link count 2) |
| Outside laboratory path | PASS | Rejected |
| Path traversal | PASS | Rejected |
| JSONL audit log | PASS | One quarantine and one restore record; valid JSON |
| xattr preservation | NOT TESTED | `setfattr`/`getfattr` tools unavailable in that run |

## Automated regression suite

| Item | Result |
|---|---|
| Runner syntax validation | PASS — checked while preparing this bundle |
| Python checker syntax validation | PASS — checked while preparing this bundle |
| JSON fixture validation | PASS — checked while preparing this bundle |
| Agent regression run | Pending |
| Manager FIM integration check | Pending |
| Export actual matching audit/FIM evidence | Pending |

Do not change this report to Completed until both the Agent regression runner and Manager FIM integration check pass and the actual output/evidence is saved.
