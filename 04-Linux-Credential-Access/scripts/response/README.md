# Project 04 — Active Response Script

`p04-lock-test-account.sh` is a Wazuh 4.x custom Active Response script designed for the stateless `add` event. It reads the JSON message from STDIN and acts only for rule `100042` when the alert AUID matches the current UID of `p04-labuser`.

## Safety conditions

- The response target is fixed to `p04-labuser`.
- The script refuses a missing/invalid AUID, an unexpected command, a different rule ID, a missing user or a UID below 1000.
- It locks only when `passwd -S` reports `P`; an already locked account is logged and skipped.
- It does not run `iptables`, does not disable other accounts and does not unlock automatically.
- `passwd -l` locks password authentication only; it does not terminate an existing session or necessarily disable SSH key authentication.

## Deployment prerequisites

1. Finish synthetic regression including different AUID.
2. Finish live Auditd detection from a real SSH session as `p04-labuser` with Active Response still disabled.
3. Confirm `command -v jq` on `my-agent`.
4. Copy the script to `/var/ossec/active-response/bin/` with owner `root:wazuh` and mode `0750`.
5. Add the separate Manager fragment in `wazuh/configs/manager-active-response.xml` only after validating the script and the live detection path.

Do not install or enable this script as part of the documentation import.
