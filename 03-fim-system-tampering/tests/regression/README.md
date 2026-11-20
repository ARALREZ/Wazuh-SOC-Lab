# Quarantine Regression Suite

## Location and execution

The suite runs on `my-agent` as root. The repository runner must be copied to the Agent (or the repository must be available there) and compared with the deployed utility before execution.

```bash
sudo bash tests/regression/run-quarantine-regression.sh
```

It prints a unique `TEST_ID` and writes:

- `/var/tmp/<TEST_ID>-regression.log` — complete console output;
- `/var/tmp/<TEST_ID>-summary.json` — PASS/SKIP/FAIL and exit code;
- `/var/tmp/<TEST_ID>-quarantine-audit.jsonl` — matching quarantine/restore records.

## Coverage

The runner validates initialization and protected permissions, regular-file quarantine, payload SHA256, manifest version 2, inode and metadata, ACL if tools are available, user xattr using Python's `os.setxattr/os.getxattr`, restore overwrite protection, successful restore, symlink/FIFO/hardlink/outside/traversal refusal, restore-item symlink refusal and JSONL audit integrity.

The external `attr` package is not required. If the filesystem does not support the user xattr operation, the runner records an explicit SKIP reason.

## Manager-side check

After saving the Agent `TEST_ID`, run the existing `tests/integration/check-fim-alerts.py` on `my-server` using the exact command/arguments documented in `tests/integration/README.md`. It must inspect only the current test ID and preserve original `alerts.json` byte-for-byte. The expected result for ordinary quarantine fixtures is baseline rule `100030`; sensitive rules `100031–100037` should not fire for benign lab fixture operations.

## Reporting

Do not report a regression PASS until the Agent suite and Manager-side check have both completed and actual outputs are saved. Record PASS, FAIL, SKIP and the reason for every SKIP. A historical run is not a substitute for a new run after changing test code.
