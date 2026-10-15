# GCP Event Decoding

Wazuh includes a GCP base rule (`65000`) for events decoded as JSON
with the field `integration` set to `gcp`.

The custom IAM detection rule (`100110`) depends on the decoded field
`gcp.protoPayload.methodName`.

Expected matching condition:
- Parent rule: `65000`
- Field: `gcp.protoPayload.methodName`
- Value: `SetIamPolicy`

The rule has matched the synthetic event in `wazuh-logtest`.
A real event must still be validated through the complete collection pipeline.

Do not add a custom decoder unless testing shows the built-in JSON decoding
does not expose the required fields.
