# Manager-side FIM Integration Check

`check-fim-alerts.py` is the Manager-side evidence checker for a specific Agent test ID. Run it on `my-server`, where `/var/ossec/logs/alerts/alerts.json` is available.

Before running, inspect its current usage and options:

```bash
python3 tests/integration/check-fim-alerts.py --help
```

If the script does not expose `--help`, read its argument parser at the top of the file and use the invocation defined there. Supply the exact TEST_ID printed by the Agent regression runner. Do not run it against all historic alerts as if they belonged to the current test.

The checker must select only events for the supplied TEST_ID/fixture path, report actual rule IDs and counts, distinguish `100030` from sensitive rules `100031–100037`, retain only Who-data fields present, skip malformed/NUL-containing lines explicitly without editing source `alerts.json`, and export sanitized JSONL with a checksum.

Save actual output under `reports/test-runs/`, with alert extracts under `evidence/alerts/` and Who-data extracts under `evidence/whodata/`. Preserve the original TEST_ID in every filename.
