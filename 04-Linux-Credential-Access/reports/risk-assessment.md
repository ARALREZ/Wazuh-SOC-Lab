# Project 04 — Risk Assessment

| Risk | Impact | Mitigation / acceptance condition |
|---|---|---|
| Locking administrator `aralrez` | Loss of administrative access | Script has a fixed allow-list target `p04-labuser`; it also compares alert AUID with the account's current UID. Never use alert data as an arbitrary username. |
| Locking the wrong login identity | Unintended account lockout | Require rule ID 100042, numeric `audit.auid`, UID >= 1000 and exact equality with `id -u p04-labuser`. |
| Duplicate Auditd rules | Reload error or confusing telemetry | Check `auditctl -l` and rules.d before install; keep exactly one `shadow_access` rule. The duplicate created during setup was removed. |
| Duplicate Agent audit.log localfile | Duplicate event ingestion | Keep exactly one `<localfile>` for `/var/log/audit/audit.log`; current count is one. |
| Correlation threshold misfire | Early/late critical alert | Regression tests include 1–5 same-AUID events and different-AUID boundary; live sequence must confirm `100042` on fifth attempt before Active Response. |
| Active Response JSON parsing failure | Missed or incorrect response | Require `jq`, parse the Wazuh 4.14 JSON payload, validate the command/rule/AUID and log skips/errors. Test JSON using controlled fixtures before enabling. |
| Password lock interpreted as full account isolation | Overstated containment | Describe as password-authentication lock only; it does not terminate active sessions or necessarily disable SSH public-key authentication. |
| Existing project response rules changed | Regression in Projects 01–03 | Add only a distinct Project 04 command and active-response block for 100042; preserve existing firewall-drop blocks. |
| Premature Active Response enablement | Lockout before detection behavior is proven | Complete synthetic and live detection-only tests before enabling response. |
| Evidence or secrets committed | Credential exposure / false claims | Evidence register, sanitization, no secrets/client.keys, and Git diff limited to Project 04. |

## Residual limitations

- `audit.auid` identifies the login UID associated with the session; test from a real SSH login as `p04-labuser`, not via `sudo -u`.
- `passwd -l` locks password authentication and is not a full host isolation mechanism.
- A synthetic `wazuh-logtest` match is not proof of live Auditd forwarding or Active Response execution.
