# Project 04 — Test Strategy

## Test layers

| Layer | Host | Tool / location | Purpose |
|---|---|---|---|
| Rule/config syntax | Fedora / Manager | XML parser, `wazuh-analysisd -t` | Ensure rule file is valid and loadable. |
| Agent configuration | `my-agent` | `wazuh-logcollector -t`, `wazuh-agentd -t` | Ensure audit log collector and Agent config are valid. |
| Auditd rule state | `my-agent` | `auditctl -l`, `augenrules --load` | Ensure exactly one active `shadow_access` rule. |
| Synthetic rule tests | `my-server` | `wazuh-logtest` | Verify positive, negative, correlation and boundary logic. |
| Live integration | Kali → `my-agent` → `my-server` | SSH, Auditd, Manager alerts | Prove real event generation and forwarding. |
| Active Response | Manager and Agent | Wazuh execd, `active-responses.log`, `passwd -S` | Prove lock is limited to the dedicated test account. |
| Recovery | `my-agent` | `cleanup_credential.sh` | Restore `p04-labuser` to state P and verify administrator unchanged. |

## Safety rules

- Use only the isolated lab and systems you own or are authorized to test.
- Run the live access test as a real `p04-labuser` SSH login; do not use `sudo -u p04-labuser` because the session AUID may remain the administrator UID.
- Do not enable Active Response until live detection without response has passed.
- Do not modify Projects 01–03 rules or their existing Active Response blocks.
- Do not add a duplicate Auditd rule or duplicate audit.log localfile entry.
- Cleanup may unlock only `p04-labuser`.
- Do not use `git clean`, `git reset --hard`, global stash or `git add -A`.

## Interpretation

A `wazuh-logtest` PASS means the supplied synthetic event matched a rule. It does not prove live syscalls, log forwarding, Manager alert delivery, Active Response or recovery. Record each layer separately in `reports/test-results.md`.
