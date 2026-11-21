# Project 01 — Evidence Register

**Scenario:** SSH Authentication Attack Detection & Active Response\
**Platform baseline:** Wazuh `4.14.10-1` (see Project 00)\
**Documentation review:** 2026-11-21

## 1. Evidence policy

Keep only sanitized evidence captured from the authorized lab. Do not commit passwords, private keys, `client.keys`, API tokens, service credentials or unredacted authentication material.

A screenshot's presence in Git proves only that the file exists. It does not prove that the image shows the final test cycle. Before marking evidence reviewed, inspect the image and confirm the host, rule ID, source address, timestamp and relevant result.

Keep synthetic `wazuh-logtest` output separate from live SSH, Active Response and firewall evidence.

## 2. Detection screenshots

| File | Required content | Inventory status |
|---|---|---|
| `100001_soft.png` | Rule `100001`, level 6, soft detection | PRESENT — visual review required |
| `100002_brute_force.png` | Rule `100002`, level 10, Kali source | PRESENT — visual review required |
| `100003_publickey.png` | Rule `100003`, level 6, failed public-key event | PRESENT — visual review required |
| `100004_password_spraying.png` | Rule `100004`, level 10, multiple usernames from one source | PRESENT — visual review required |
| `100005_critical.png` | Rule `100005`, level 14, successful login correlated with earlier failures | PRESENT — confirm it is the final live test |
| `100010_trusted_ip.png` | Rule `100010`, level 3, trusted source `192.168.122.1` | PRESENT — visual review required |

## 3. Active Response and firewall screenshots

| File | Required content | Inventory status |
|---|---|---|
| `active_responses_log.png` | Agent `/var/ossec/logs/active-responses.log`; relevant `add` and `delete` records | PRESENT — verify the final `100002` / `100005` cycles |
| `ar_blocked_ip.png` | Evidence that a new SSH connection from Kali is blocked during the response window | PRESENT — visual review required |
| `iptables_drop.png` | Actual firewall DROP rule for `192.168.122.112` on `my-agent` | PRESENT — visual review required |
| `iptables_drop_kali.png` | Additional Kali-side firewall / connectivity evidence | PRESENT — verify that it adds distinct evidence |

For each trigger rule, the strongest evidence set correlates the same test cycle across:

1. Manager alert (`100002` or `100005`).
2. Agent Active Response `add` record.
3. Actual DROP rule on `my-agent`.
4. Failed new SSH connection from Kali during the block.
5. Agent Active Response `delete` record after the 600-second timeout.
6. Successful new SSH connection from Kali after the automatic unblock.

Do not manually delete the DROP rule to simulate a successful timeout. The test must demonstrate Wazuh's automatic delete behavior. The configured timeout in the current reference file is 600 seconds for both rules.

## 4. Regression evidence

| File | Required content | Inventory status |
|---|---|---|
| `regression-summary.png` | Final summary for the 17 fast cases and all 6 slow cases | NOT PRESENT — capture after both suites pass |

The runner's `--include-slow` option executes all 17 fast cases again and then the six slow cases (23 total). Do not label a 17-case historical run as the current 23-case result. If a test fails or is interrupted, report the actual outcome.

## 5. Evidence acceptance criteria

- [ ] Screenshot opens and is legible.
- [ ] Host and test source are identifiable.
- [ ] Correct rule ID and level are visible for detection screenshots.
- [ ] Timestamps are consistent across Manager alert, Agent response, firewall and client-side evidence.
- [ ] Rule `100005` screenshot shows the successful authentication event, not only a failed-login event.
- [ ] `add`, actual DROP, blocked connection, automatic `delete` and restored connection belong to the same Active Response cycle.
- [ ] Trusted-source evidence shows `192.168.122.1` as observed by the Agent.
- [ ] Sensitive information and unrelated user data are redacted.
- [ ] Regression summary is created only after the current test suites pass.

## 6. Related records

- Actual test state: `reports/test-results.md`
- Expected regression behavior: `tests/regression/expected-results.md`
- Detection rules: `wazuh/rules/ssh_brute_force_rules.xml`
- Active Response reference: `wazuh/configs/active-response.xml`
