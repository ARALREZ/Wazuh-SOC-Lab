# GCP Cloud Audit — test results

Date: 2026-10-14
Environment: Wazuh 4.14.7
Rule ID: 100110
Rule level: 5

## Positive test

- Input: `tests/positive/iam-policy-change.json`
- Operation: `SetIamPolicy`
- Expected: rule 100110 matches
- Observed: rule 100110 matched, level 5
- Result: PASS

## Negative test

- Input: `tests/negative/iam-policy-read.json`
- Operation: `GetIamPolicy`
- Expected: rule 100110 does not match
- Observed: Phase 3 did not report rule 100110
- Result: PASS

## Limitations

Both tests use synthetic logs submitted to `wazuh-logtest`.
They do not establish that live Google Cloud Audit Logs are reaching Wazuh.

## End-to-end validation — real GCP IAM event

- **Status:** PASS
- **Source:** Google Cloud Audit Logs
- **Project:** `project-f2f7b861-fe1c-4052-ad8`
- **Event method:** `SetIamPolicy`
- **Change:** Added `roles/browser` to the test account
- **Wazuh rule ID:** `100110`
- **Wazuh rule level:** `5`
- **Alert description:** `Google Cloud Audit: IAM policy change detected`
- **Wazuh alert timestamp:** `2026-10-14T21:56:21.558+0000`
- **GCP event timestamp:** `2026-10-14T21:56:16.982493Z`
- **GCP insertId:** `jgisfle19u20`
- **Evidence source:** Wazuh manager `/var/ossec/logs/alerts/alerts.json`
- **Result:** A real GCP IAM policy-change event reached Wazuh and matched rule `100110`.
