# Project 03 — Test Results

**Report date:** 2026-11-19  
**Project status:** IN PROGRESS — previous live tests and quarantine scenarios validated; corrected regression execution and Manager integration verification pending.  
**Platform baseline:** Wazuh 4.14.10-1; installation and enrollment are documented in Project 00.

## 1. Environment

| Component | Host | Role | Address |
|---|---|---|---|
| Wazuh Manager | `my-server` | Rule analysis and alerts | `192.168.122.178` |
| Wazuh Agent | `my-agent` | FIM/Who-data endpoint, Agent 001 | `192.168.122.208` |
| Test host | Kali | Authorized lab test source | `192.168.122.112` |
| Admin workstation | Fedora | Project administration | `192.168.122.1` as observed from the VM network |

## 2. Live FIM rule validation

| Rule | Level | Scenario | Recorded result |
|---|---:|---|---|
| 100030 | 5 | Baseline FIM event in lab watch | PASS |
| 100031 | 10 | Temporary SSH configuration change under `sshd_config.d` | PASS |
| 100032 | 12 | `authorized_keys` change | PASS |
| 100033 | 12 | Cron persistence file creation/change | PASS |
| 100034 | 14 | Correlated sensitive changes by same valid audit UID | PASS in an earlier historical series; do not substitute the later missing TEST_ID |
| 100035 | 12 | Systemd persistence configuration change | PASS |
| 100036 | 13 | Critical-file deletion; tested in isolation with rule 100034 temporarily disabled | PASS |
| 100037 | 12 | Sensitive permission/ownership change; tested in isolation with rule 100034 temporarily disabled | PASS |

The exact rule definition and event conditions remain in `wazuh/rules/fim_system_tampering_rules.xml`. The screenshots under `evidence/` are present in the local inventory according to the operator; final image-content review is still required before publication.

## 3. Historical FIM regression run

Run ID: `p03-regression-20261117T183221Z-4501` (Agent 001, 2026-11-17).

| Metric | Result |
|---|---:|
| PASS | 16 |
| SKIP | 1 |
| FAIL | 0 |

The single SKIP was xattr because the then-current runner required `setfattr/getfattr`, which were unavailable. This is a historical result and must not be presented as the result of the corrected runner in this package.

The Manager-side integration evidence recorded 12 FIM alerts, all rule `100030` level 5; no rules `100031–100037` fired during benign quarantine fixture operations. Who-data identified login user `aralrez` (UID 1000); observed processes included `bash`, `rm` and `ln`. The original Manager `alerts.json` was not modified. The checker skipped one malformed/NUL-containing record.

Historical evidence files:
- `reports/test-runs/p03-regression-20261117T183221Z-4501-regression.log`
- `reports/test-runs/p03-regression-20261117T183221Z-4501-summary.json`
- `evidence/alerts/p03-regression-20261117T183221Z-4501-fim-alerts.jsonl`
- `evidence/whodata/p03-regression-20261117T183221Z-4501-whodata.jsonl`
- `evidence/quarantine/p03-regression-20261117T183221Z-4501-quarantine-audit.jsonl`

## 4. Manual quarantine test cases 1–11

The operator handoff dated 2026-11-19 confirms all eleven manual scenarios passed:

| No. | Test | Result |
|---:|---|---|
| 1 | Quarantine regular file | PASS |
| 2 | SHA256, inode and metadata preservation | PASS |
| 3 | Restore | PASS |
| 4 | POSIX ACL preservation | PASS |
| 5 | User xattr preservation | PASS — separate final Python API check |
| 6 | Outside-watch path refusal | PASS |
| 7 | Path traversal refusal | PASS |
| 8 | Symlink and hardlink refusal | PASS |
| 9 | FIFO/special-file refusal | PASS |
| 10 | Restore overwrite protection and restore after conflict removal | PASS |
| 11 | JSONL audit and rejected-operation handling | PASS |

### Negative runner

Run ID: `p03-stage3-negative-20261119T183501Z-3886`.

- PASS: 10
- FAIL: 0
- FINAL_STATUS: PASS
- Report: `reports/test-runs/p03-stage3-negative-20261119T183501Z-3886-results.txt`
- SHA256: `4c72c9b6f9732289e35f8896482d52511be6414c766ffb59f57a800c65f8efb1`

This runner's `TOTAL=10` counts its assertions; it is not ten additional named scenarios beyond the eleven-case manual list.

### Independent xattr check

Run ID: `p03-xattr-final-20261119T183828Z-4737`.

- xattr name: `user.project03_final`
- value: `project03-final-xattr-check`
- file SHA256 before/after: `fe60437dcdc5c2674cf77bbd04c4120dfd1bf39eb237be2abe683c825adab88a`
- xattr value SHA256: `8c11ad598ead8b770ca7e39dfce794ab0638974d650288d5c311923954119bf7`
- final result: `FINAL_STATUS=PASS`

### Quarantine audit extract

`evidence/quarantine/p03-stage3-quarantine-audit.jsonl` contains four valid JSON records: two quarantine and two restore. They map to the negative runner and independent xattr run. SHA256: `8edeca61cec0855d05b8992daf5f1061cb5359167d7a77b3e7cc1ea3673bad6f`.

## 5. Corrected regression execution — pending

The previous runner compared the generated manifest to version 1 although the deployed quarantine utility writes manifest version 2. It also depended on external `setfattr/getfattr`. The replacement runner in `tests/regression/run-quarantine-regression.sh` validates manifest version 2 and uses Python `os.setxattr/os.getxattr`.

Do not fill in PASS/SKIP/FAIL for this new run until it has actually been executed on `my-agent`. After it completes, run the Manager-side `tests/integration/check-fim-alerts.py` with that exact TEST_ID using the usage documented in `tests/integration/README.md`, then copy the actual report, summary and sanitized audit/alert extracts into the repository.

## 6. Evidence capture status

- Eight rule screenshots `100030–100037`: present in the local project tree according to the operator; review visual content before publication.
- Quarantine screenshots 01–04: operator reports successful captures.
- Quarantine screenshots 05–06: present in the local project inventory; visual review and checksum verification required.
- `regression-summary.png`: pending until the corrected runner and Manager integration check complete.

## 7. Known limitations

- No dedicated fault-injection test for an audit log write failure.
- No dedicated race/concurrent-source-replacement test.
- Atomic same-filesystem rename preserves inode in the tested ext4 environment; it is not proof that all race conditions are eliminated.
- ACL and user xattr tests cover concrete lab examples, not every filesystem or namespace.
- The watch directory is owned by `aralrez:aralrez` and mode `750`; a user who can write there can change fixtures while an administrator is preparing a response.
- One malformed/NUL-containing Manager `alerts.json` record was skipped by the reporting checker; the raw file was not edited.

## 8. Final assessment

Live rule validation and manual quarantine tests are documented as PASS based on the lab handoff. The corrected repeatable regression has **not yet been run**, and the six quarantine screenshot files are present in the local inventory, but the regression summary image and corrected regression execution remain pending. Project 03 therefore remains **IN PROGRESS**.

<!-- P03_FINAL_VALIDATION_2026-11-20_START -->
## Final regression snapshot — 2026-11-20

- Quarantine: 19 PASS / 0 SKIP / 0 FAIL.
- Rule XML validation: PASS.
- Manager analysisd validation: PASS.
- Agent hash/service validation: PASS.
- Live benign-watch negative FIM test: PASS.
- Screenshot inventory: 14/15 valid PNG files.

The final validation report distinguishes fresh negative-test evidence from previous live positive tests for 100031–100037. It does not treat wazuh-logtest or screenshot names alone as proof of a new end-to-end test.

See `test-runs/p03-final-validation-20261120T092321Z.md`.
<!-- P03_FINAL_VALIDATION_2026-11-20_END -->
