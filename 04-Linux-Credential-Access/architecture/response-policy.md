# Project 04 — Active Response Policy

## Response objective

On a critical alert `100042`, lock password authentication for the one dedicated test account `p04-labuser`. Do not lock the administrator, other users or the source IP.

## Preconditions

The script may proceed only when all conditions are true:

1. Wazuh JSON was received from STDIN and parsed successfully.
2. `.command` is `add` (stateless response; no `delete` handler is configured).
3. `.parameters.alert.rule.id` is exactly `100042`.
4. An integer `audit.auid` exists in the alert.
5. `p04-labuser` exists and its current UID is at least 1000.
6. The alert AUID equals the current UID of `p04-labuser`.
7. `passwd -S p04-labuser` reports `P` (usable password, not already locked).

If any identity condition fails, the script skips the action and writes a reason to `/var/ossec/logs/active-responses.log`. An unexpected password state is refused rather than changed.

## Wazuh configuration fragment

`wazuh/configs/manager-active-response.xml` is a fragment to be inserted into the existing Manager `/var/ossec/etc/ossec.conf`, inside its existing `<ossec_config>` structure. It is not a replacement file.

```xml
<command>
  <name>p04-lock-test-account</name>
  <executable>p04-lock-test-account.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <command>p04-lock-test-account</command>
  <location>local</location>
  <rules_id>100042</rules_id>
</active-response>
```

`location=local` runs the command on the Agent associated with the alert. Existing Active Response commands and blocks from Projects 01–03 must remain unchanged.

## Stateless behavior and recovery

`timeout_allowed=no` is intentional. No automatic `delete` action is expected. After testing, an administrator manually unlocks only `p04-labuser` using `scripts/cleanup_credential.sh` and verifies `passwd -S p04-labuser` reports `P`.

## Limitations

`passwd -l` locks password authentication; it does not terminate an established session or prove that public-key authentication is disabled. Do not describe this action as full host isolation or full account disablement.

## Deployment state

The policy and scripts are prepared as repository references. They are **not yet installed/enabled** in the live Wazuh configuration at the implementation snapshot date.
