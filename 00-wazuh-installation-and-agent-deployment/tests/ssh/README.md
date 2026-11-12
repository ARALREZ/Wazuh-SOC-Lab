# SSH Detection Tests

See [the SSH validation procedure](../../docs/06-ssh-event-ingestion-smoke-test.md).

Record each test with:

- Test date/time and timezone.
- Source host and source IP.
- Target host (`my-agent`, `192.168.122.208`).
- Number and type of controlled attempts.
- Matching local SSH journal events.
- Matching Wazuh alert timestamps, agent name, rule description, and rule ID.
- Result: PASS / FAIL / NOT TESTED.

Use only a dedicated non-privileged lab account. Redact usernames or other details where needed. Never record passwords.
