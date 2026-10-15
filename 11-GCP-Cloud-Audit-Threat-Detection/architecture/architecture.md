# Architecture — GCP Cloud Audit & IAM Threat Detection

## Objective
Detect Google Cloud IAM policy changes using Cloud Audit Logs,
Pub/Sub, and Wazuh custom detection rules.

## Event flow
1. A relevant IAM operation occurs in Google Cloud.
2. Cloud Audit Logs records the operation.
3. A Cloud Logging sink must route matching audit entries to a Pub/Sub topic.
4. The Pub/Sub subscription makes messages available to the Wazuh GCP module.
5. Wazuh decodes the event and evaluates its rules.
6. Rule 100110 should alert when the event contains
   `gcp.protoPayload.methodName` equal to `SetIamPolicy`.

## Components
- Google Cloud Audit Logs
- Cloud Logging sink (delivery must be verified)
- Pub/Sub topic: `wazuh-gcp-topic`
- Pub/Sub subscription: `wazuh-gcp-topic-sub`
- Wazuh Manager and GCP Pub/Sub module
- Custom rule ID: `100110`

## Validation status
- Manual Pub/Sub message retrieval: confirmed.
- Manual Wazuh script received a test message: confirmed.
- Custom rule matching in `wazuh-logtest`: confirmed.
- End-to-end alert from a real GCP audit event: not yet confirmed.

## Security notes
- Never commit service-account credentials or private keys.
- Keep credentials readable only by the required service account and administrators.
- Use least-privilege IAM permissions.
