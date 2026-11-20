# Project 03 — Step 4 bundle

This bundle adds a repeatable quarantine regression suite, a Manager-side FIM alert checker, test-case fixtures, the JSONL audit schema, and a test-results template.

## Install carefully on Fedora

From the Project 03 directory, extract this archive with `unzip -n` so existing files are not overwritten.

## Execution order

1. Validate shell/Python syntax and JSON fixtures on Fedora.
2. Run the Agent regression runner on `my-agent` as root and save its TEST_ID.
3. Run the Manager FIM alert checker on `my-server` using that exact TEST_ID.
4. Export actual matching logs and update the results report using the real output.

This bundle does not change Wazuh rules, `ossec.conf`, Active Response, or the quarantine program itself.
