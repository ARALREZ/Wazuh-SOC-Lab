# Project 04 — Active Response Policy

## Objective

On critical alert `100042`, lock password authentication for the fixed dedicated lab account `p04-labuser` only.

## Preconditions

The response script requires:

1. Valid Wazuh JSON on STDIN.
2. `command=add`.
3. Alert rule ID exactly `100042`.
4. Alert Agent ID exactly `001`.
5. Numeric Auditd AUID present.
6. `p04-labuser` exists and has UID >= 1000.
7. Alert AUID equals the current UID of `p04-labuser`.
8. Password state is `P` before locking; state is verified as `L` afterwards.

Any mismatch is skipped or refused and logged. The username is hard-coded; it is never accepted from alert data.

## Manager fragment

`wazuh/configs/manager-active-response.xml` is a fragment for the existing Manager `/var/ossec/etc/ossec.conf`, not a replacement file. Insert the command/response once and preserve Projects 01–03 blocks.

```xml
<command>
  <name>p04-lock-test-account</name>
  <executable>p04-lock-test-account.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>
<active-response>
  <disabled>no</disabled>
  <command>p04-lock-test-account</command>
  <location>local</location>
  <rules_id>100042</rules_id>
</active-response>
```

The `disabled` element is mandatory in Wazuh 4.x Active Response blocks. `no` enables the response.

## Recovery and limitations

The response is stateless; automatic unlock is not configured. After evidence capture, an administrator manually unlocks only `p04-labuser` and verifies `p04-labuser=P`, `aralrez=P`.

`passwd -l` locks password authentication only. It does not terminate an existing session or prove SSH public-key authentication is disabled. This is not host isolation.

The live response for rule 100042/AUID 1008 was confirmed in the Agent response log.
