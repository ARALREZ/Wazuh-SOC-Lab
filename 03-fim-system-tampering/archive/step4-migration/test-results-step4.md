# Archived Historical Test Report — 2026-11-17

Run ID: `p03-regression-20261117T183221Z-4501`.

Historical result: PASS 16 / SKIP 1 / FAIL 0. The SKIP was xattr because `setfattr/getfattr` were unavailable in that runner. The later independent Python xattr run on 2026-11-19 passed. See `reports/test-results.md` for the consolidated status.

Manager integration: 12 baseline FIM alerts, all rule 100030 level 5; no rules 100031–100037 fired for benign lab quarantine fixtures. Who-data identified login user `aralrez` UID 1000; processes observed included bash, rm and ln. One malformed/NUL-containing alert record was skipped by the checker; raw `alerts.json` was not modified.

Evidence hashes recorded in the source report:
- Manager FIM evidence: `c0f4f910630e24f01d5c3d3054407fd9ad295ee6d50268256bcbcdcf99f62310`
- Quarantine audit: `8608163fb3785bdbf87512fe392aafeed4e19dc9d685c177d9d69f9ef1b804b1`
