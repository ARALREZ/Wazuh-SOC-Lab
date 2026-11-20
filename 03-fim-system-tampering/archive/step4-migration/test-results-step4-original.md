# Project 03 — Regression and Quarantine Test Results

Date: 2026-11-17

Agent: my-agent (001), 192.168.122.208
Manager: my-server, 192.168.122.178

## Test identification

TEST_ID: p03-regression-20261117T183221Z-4501

## Regression summary

| Metric | Result |
|---|---:|
| PASS | 16 |
| SKIP | 1 |
| FAIL | 0 |

Result: PASS, with one documented skip.

## Tested quarantine functionality

- Quarantine initialization and directory permissions.
- Payload SHA256 integrity.
- Manifest structure and validation.
- File restoration.
- SHA256 preservation after restoration.
- Owner, group, permissions, size and modification time.
- ACL preservation.
- Refusal to overwrite an existing destination.
- Symlink rejection.
- FIFO/special file rejection.
- Hardlink rejection.
- Outside-root path rejection.
- Path traversal rejection.
- Symlink quarantine-item rejection.
- JSONL audit validation and export.

## xattr limitation

The extended attribute test was skipped because setfattr/getfattr
were unavailable on the Agent.

No PASS is claimed for xattr preservation.

## File integrity

SHA256 of the regression fixture:

c985a1949c2ec1cd0143129fc6aff70989c1f434d8ee9a0aed78dc065c50065f

ACL was verified before quarantine, inside quarantine and after restore.

## Wazuh Manager integration

Agent ID: 001

Matching FIM alerts: 12

Rule counts:

| Rule | Count |
|---|---:|
| 100030 | 12 |
| 100031–100037 | 0 |

All 12 alerts belonged to the baseline FIM rule 100030,
level 5.

Events were observed under:

/opt/wazuh-fim-lab/watch/

Who-data identified login user aralrez (UID 1000).

Observed process names included:

- /usr/bin/bash
- /usr/bin/rm
- /usr/bin/ln

No sensitive system-tampering rule was triggered by these
laboratory test operations.

## Evidence files

- reports/test-runs/p03-regression-20261117T183221Z-4501-regression.log
- reports/test-runs/p03-regression-20261117T183221Z-4501-summary.json
- evidence/quarantine/p03-regression-20261117T183221Z-4501-quarantine-audit.jsonl
- evidence/alerts/p03-regression-20261117T183221Z-4501-fim-alerts.jsonl
- evidence/whodata/p03-regression-20261117T183221Z-4501-whodata.jsonl

Manager FIM evidence SHA256:

c0f4f910630e24f01d5c3d3054407fd9ad295ee6d50268256bcbcdcf99f62310

Quarantine audit SHA256:

8608163fb3785bdbf87512fe392aafeed4e19dc9d685c177d9d69f9ef1b804b1

## Data quality notes

The Manager checker skipped one malformed/NUL-containing
record in alerts.json. The original alerts.json was not modified.

## Final assessment

Regression suite: PASS.
Wazuh FIM integration: PASS.
Quarantine/restore: PASS.
ACL preservation: PASS.
xattr: SKIP.

Project 03 remains In Progress pending subsequent stages
and final repository review.
